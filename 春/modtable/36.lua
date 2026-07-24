
local save_id, str_auto, img_show = "sw_watering", "自动浇灌", "wateringcan"
local default_data = {
    
    towater = true,
    
    tofill = true,
    
    tosay = true,
    
    
    perwater = 90,
    perfill = 90,
    
    range = 40
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function Say(str)
    if str and save_data.tosay then
        u_util:Say(str_auto, str, "head", "蓝色", true)
    end
    return true
end
local prefabs_inv = {"wateringcan", "premiumwateringcan"}
local function GetMoisture(nut)
    local wet = nut and nut.AnimState and nut.AnimState:GetCurrentAnimationTime() or 1
    return wet < 0 and 0 or (wet > 1 and 1 or wet)
end
local function fn_left()
    local pusher = m_util:GetPusher()
    if not pusher then
        return
    end
    if pusher:GetNowTask() then
        return pusher:StopNowTask()
    end
    local flag = save_data.towater and "浇灌模式" or "填充模式"

    pusher:RegNowTask(function(player, pc)
        if save_data.towater and flag == "浇灌模式" then
            local nuts = e_util:FindEnts(nil, "nutrients_overlay", save_data.range, nil, {})
            if not nuts[1] and not save_data.tofill then
                return Say("附近没有耕地")
            end
            local nut = t_util:IGetElement(nuts, function(nut)
                return GetMoisture(nut) * 100 < save_data.perwater and nut
            end)
            if nut then
                local tool = p_util:GetItemFromAll(prefabs_inv, nil, function(item)
                    return e_util:GetPercent(item) > 1
                end, {"equip", "body", "backpack", "container"})
                if tool then
                    
                    if p_util:GetEquip("hands") == tool then
                        local pos = nut:GetPosition()
                        local act = p_util:GetAction("pos", "POUR_WATER_GROUNDTILE", true, tool, nil, pos)
                        if act then
                            p_util:DoAction(act, RPC.RightClick, act.action.code, pos.x, pos.z, act.target,
                                act.rotation, true, nil, nil, act.action.mod_name)
                        end
                    else
                        p_util:Equip(tool)
                    end
                else
                    tool = p_util:GetItemFromAll(prefabs_inv, nil, nil, {"equip", "body", "backpack", "container"})
                    if tool then
                        
                        if save_data.tofill then
                            flag = "填充模式"
                            Say(flag)
                            return
                        else
                            return Say("水壶没水了")
                        end
                    else
                        return Say("没有找到水壶")
                    end
                end
            elseif save_data.tofill then
                
                local tool = p_util:GetItemFromAll(prefabs_inv, nil, function(item)
                    return e_util:GetPercent(item) < save_data.perfill
                end, {"equip", "body", "backpack", "container"})
                if tool then
                    flag = "填充模式"
                    Say(flag)
                    return
                end
            end
        elseif save_data.tofill and flag == "填充模式" then
            local tool = p_util:GetItemFromAll(prefabs_inv, nil, function(item)
                return e_util:GetPercent(item) < save_data.perfill
            end, {"equip", "body", "backpack", "container"})
            if tool then
                if p_util:GetEquip("hands") == tool then
                    local act
                    local pond = e_util:FindEnt(nil, nil, save_data.range, nil, nil, nil, nil, function(ent)
                        act = p_util:GetAction("equip", "FILL", true, tool, ent)
                        return act
                    end)
                    if pond then
                        local pos = pond:GetPosition()
                        p_util:DoAction(act, RPC.RightClick, act.action.code, pos.x, pos.z, pond, act.rotation, nil,
                            nil, true, act.action.mod_name)
                    else
                        m_util:print("没有水塘")
                    end
                else
                    p_util:Equip(tool)
                end
            else
                flag = "浇灌模式"
                Say(flag)
                return
            end
        else
            return Say("没有任务")
        end
        m_util:print(flag)
        d_util:Wait(.5)
    end, function()
        u_util:Say(str_auto, "结束")
    end)
end

local r_data = require("data/valuetable")
local fn_right = m_util:AddBindShowScreen{
    title = "自动浇灌 高级设置",
    id = save_id,
    data = {{
        id = "towater",
        label = "浇灌耕地",
        fn = fn_save("towater"),
        hover = "是否自动浇灌耕地",
        default = fn_get
    }, {
        id = "perwater",
        label = "耕地湿度:",
        fn = fn_save("perwater"),
        hover = "耕地水分浇灌到该数值时停止浇灌",
        type = "radio",
        data = t_util:BuildNumInsert(5, 95, 5, function(i)
            return {
                data = i,
                description = i .. "%"
            }
        end),
        default = fn_get
    }, {
        id = "tofill",
        label = "填充水壶",
        fn = fn_save("tofill"),
        hover = "是否自动填充水壶",
        default = fn_get
    }, {
        id = "perfill",
        label = "水壶容量:",
        fn = fn_save("perfill"),
        hover = "空闲状态时，水壶需要保持此耐久以上",
        type = "radio",
        data = t_util:BuildNumInsert(5, 95, 5, function(i)
            return {
                data = i,
                description = i .. "%"
            }
        end),
        default = fn_get
    }, {
        id = "tosay",
        label = "文字提示",
        fn = fn_save("tosay"),
        hover = "角色头上是否显示文字提示",
        default = fn_get
    }, {
        id = "range",
        label = "搜寻范围:",
        fn = fn_save("range"),
        type = "radio",
        hover = "搜寻耕地或池塘的范围",
        default = fn_get,
        data = t_util:BuildNumInsert(4, 60, 4, function(i)
            return {
                data = i,
                description = i .. " 墙点"
            }
        end)
    }},
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍",
                '自动浇灌功能由玩家"小宇"定制。\n\n留言："纯净档，小开不算开"', {{
                    text = "󰀍"
                }})
        end
    }}
}

m_util:AddBindConf(save_id, fn_left, fn_left, {str_auto, img_show,
                                               STRINGS.LMB .. '启动/结束 ' .. STRINGS.RMB .. '高级设置', true,
                                               fn_left, fn_right, 5999})
