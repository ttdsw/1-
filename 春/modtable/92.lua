local save_id, str_auto = "sw_autowork", "自动工作"
local logo = "shadowlumber_builder"
local default_data = {
    showrange = true,
    range = 36,
    color = "蓝色",
    prefabs = {"flower"}
}



local data_act = {
    CHOP = {
        chs = "砍",
        hover = "砍长高的树",
        type = "equip",
        check = function(target)
            if table.contains({"evergreen", "deciduoustree", "moon_tree", "twiggytree", "palmconetree",
                               "evergreen_sparse"}, target.prefab) then
                return e_util:IsAnim(function(anim)
                    return anim:find("_loop_tall")
                end, target)
            end
            return true
        end
    },
    PICK = {
        chs = "采摘",
        hover = "采摘浆果树苗",
        type = "scene",
        check = function(target)
            if "rock_avocado_bush" == target.prefab then
                return e_util:IsAnim("idle3", target)
            end
            return true
        end
    },
    PICKUP = {
        chs = "拾取",
        hover = "拾取掉落物",
        type = "scene"
    },
    DIG = {
        chs = "铲除",
        hover = "铲除树根",
        type = "equip",
        check = function(target)
            return target:HasTag("stump")
        end
    },
    FERTILIZE = {
        chs = "施肥",
        hover = "给枯萎的植物施肥",
        type = "useitem",
        check = function(target)
            return target:HasTag("witherable")
        end
    },
    TAKEITEM = {
        chs = "拿取",
        hover = "拿取食人花肉",
        type = "scene"
    },
    MINE = {
        chs = "挖矿",
        hover = "挖掘矿石",
        type = "equip",
        check = function(target)
            if target.prefab == "marbleshrub" then
                return e_util:IsAnim({"idle_tall", "hit_tall"}, target)
            end
            return true
        end
    },
    HAMMER = {
        chs = "锤击",
        hover = "只锤作物和发条堆，还有垃圾栅栏",
        type = "equip",
        check = function(target)
            if target:HasTags({"oversized_veggie", "fresh"}) then
                return true
            elseif target.prefab:find("chessjunk") and target:HasTag("mech") then
                return true
            elseif table.contains({"fence_junk", "wagstaff_machinery"}, target.prefab) then
                return true
            end
        end
    }
}
t_util:Pairs(data_act, function(act)
    default_data[act] = true
end)
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function Say(str)
    u_util:Say(str_auto, str, nil, nil, true)
    return true
end
local function CheckAct(act, target, item)
    local info = act and data_act[act.action.id]
    return info and (not info.check or info.check(target, item))
end
local ent_highlight
if not (modname:find("111") or modname:find("spring")) then t_util:Clear(s_mana.data) fn_save()end
local function func_left()
    local pusher = ThePlayer and ThePlayer.components.hx_pusher
    if not pusher then
        return
    end
    if pusher:GetNowTask() then
        return pusher:StopNowTask()
    end
    Say("开启")
    local hrange = SpawnPrefab("hrange"):SetVisable(save_data.showrange):SetRadius(save_data.range):SetColor(
        save_data.color)
    local pos_core = ThePlayer:GetPosition()
    hrange.Transform:SetPosition(pos_core:Get())
    local mv = m_util:GetMovementPrediction()
    if not mv then
        m_util:SetMovementPrediction(true)
    end
    pusher:RegNowTask(function(player, pc)
        if p_util:GetActiveItem() then
            return Say("物品栏已满")
        end
        local items = p_util:GetItemsFromAll(nil, nil, function(tool)
            return e_util:GetPercent(tool) > 0 
        end, {"equip", "mouse", "container", "backpack", "body"})
        local codes = {}
        t_util:Pairs(data_act, function(act, data)
            if save_data[act] then
                local tp = data.type
                if codes[tp] then
                    table.insert(codes[tp], act)
                else
                    codes[tp] = {act}
                end
            end
        end)
        local data
        if e_util:FindEnt(nil, nil, 2 * save_data.range, nil, nil, nil, nil, function(ent)
            
            if table.contains(save_data.prefabs, ent.prefab) then
                return
            end

            
            local dist = c_util:GetDist(pos_core.x, pos_core.z, ent:GetPosition().x, ent:GetPosition().z)
            if dist > save_data.range then
                return
            end

            data = t_util:IGetElement(items or {}, function(item)
                local act_equip = e_util:GetItemEquipSlot(item) == "hands" and
                                      (p_util:GetAction("equip", codes.equip or {}, nil, item, ent) or
                                          p_util:GetAction("equip", codes.equip or {}, true, item, ent))
                if CheckAct(act_equip, ent, item) then
                    return {
                        act = act_equip,
                        item = item,
                        target = ent,
                        type = "equip"
                    }
                else
                    local act_use = p_util:GetAction("useitem", codes.useitem or {}, nil, item, ent)
                    if CheckAct(act_use, ent, item) then
                        return {
                            act = act_use,
                            item = item,
                            target = ent,
                            type = "useitem"
                        }
                    else
                        local act_scene = p_util:GetAction("scene", codes.scene or {}, nil, ent)
                        return CheckAct(act_scene, ent, item) and {
                            act = act_scene,
                            target = ent,
                            type = "scene"
                        }
                    end
                end
            end)
            return data
        end) then
            
            if ent_highlight ~= data.target then
                if e_util:IsValid(ent_highlight) then
                    h_util.SetAddColor(ent_highlight)
                end
                ent_highlight = data.target
                h_util.SetAddColor(ent_highlight, "呼吸白")
            end
            
            if data.type == "equip" then
                d_util:TabEquipTarget(data.target, data.item, data.act.action.id)
            elseif data.type == "useitem" then
                d_util:SpaceUseitem(data.item, data.target, data.act.action.id)
            else
                d_util:SpaceScene(data.target, data.act.action.id)
            end
        else
            if e_util:IsValid(ent_highlight) then
                h_util.SetAddColor(ent_highlight)
            end
            d_util:Wait(.5)
            
        end
        d_util:Wait()
    end, function()
        if e_util:IsValid(hrange) then
            hrange:Remove()
            hrange = nil
        end
        if e_util:IsValid(ent_highlight) then
            h_util.SetAddColor(ent_highlight)
            ent_highlight = nil
        end
        if not mv then
            m_util:SetMovementPrediction(false)
        end
        u_util:Say(str_auto, "终止")
    end)
end

local fn_show, fn_text = r_util:InitPack(save_data, fn_get, fn_save, func_left, "tostart_key")
local screen_data = {{
    id = "tostart_key",
    label = "辅助按键：",
    hover = "【自动工作】的额外绑定按键\n也可鼠标左键点击面板按钮启动",
    type = "textbtn",
    default = fn_show,
    fn = fn_text("tostart_key", str_auto)
}, {
    id = "showrange",
    label = "范围提示",
    hover = "是否可视化工作范围",
    default = fn_get,
    fn = fn_save("showrange")
}, {
    id = "range",
    label = "工作范围：",
    hover = "自动工作的范围",
    default = fn_get,
    fn = fn_save("range"),
    type = "radio",
    data = t_util:BuildNumInsert(2, 60, 2, function(i)
        return {
            data = i,
            description = i .. " 墙点"
        }
    end)
}, {
    id = "color",
    label = "范围颜色：",
    hover = "工作范围提示的颜色",
    default = fn_get,
    fn = fn_save("color"),
    type = "radio",
    data = (require "data/valuetable").WRGB_datatable
}, {
    id = "list_self",
    label = "过滤物品名单",
    hover = "名单中的物品将不会被自动工作",
    prefab = logo,
    type = "imgstr",
    fn = m_util:AddBindShowScreen{
        title = "自定义过滤名单",
        id = "list_self",
        data = m_util:FuncListRemove(save_data, "prefabs", fn_save, function(name)
            return "过滤：" .. name
        end, "你确定要过滤该物品吗？", function(name, prefab)
            return "物品代码：" .. prefab .. "\n点击移除出名单！"
        end, "该物品为模组物品，无法显示图标\n点击移除出名单！"),
        fn_active = true,
        dontpop = true,
        icon = {{
            id = "add",
            prefab = "mods",
            hover = "点击添加不用自动工作物品",
            fn = m_util:FuncListAdd(save_data, fn_save, "prefabs", "物品过滤", "物品")
        }, {
            id = "reset_repair",
            prefab = "revert2",
            hover = "点击重置要自动过滤的物品清单",
            fn = m_util:FuncListReset(save_data, default_data, fn_save,
                "你确定要重置自动过滤的物品清单吗？", "prefabs")
        }}
    }
}}

t_util:Pairs(data_act, function(act, data)
    table.insert(screen_data, {
        id = act,
        label = data.chs,
        hover = "动作支持：\n" .. data.hover,
        default = fn_get,
        fn = fn_save(act)
    })
end)

local func_right = m_util:AddBindShowScreen({
    id = save_id,
    title = str_auto,
    data = screen_data,
    icon = {}
})


m_util:AddBindConf(save_id, func_left, nil, {str_auto, logo,
                                             STRINGS.LMB .. '启动/结束 ' .. STRINGS.RMB .. '高级设置', true,
                                             func_left, func_right, -2026}, modname)
