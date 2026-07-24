local save_id, str_auto, img_show = "sw_beebox", "火中取蜜", "beebox_crystal"
local prefab_beebox = "beebox"
local function Say(str)
    if str then
        u_util:Say(str_auto, str, nil, nil, true)
    end
    return true
end

local function fn_left()
    local pusher = m_util:GetPusher()
    if not pusher then return end
    if pusher:GetNowTask() then
        return pusher:StopNowTask()
    end
    p_util:ReturnActiveItem()
    u_util:Say(str_auto, "开始")
    pusher:RegNowTask(function()
        if p_util:GetActiveItem() then
            return Say("物品栏已满")
        end
        local beebox = e_util:FindEnt(nil, prefab_beebox, nil, nil, nil, nil, nil, function(ent)
            return p_util:GetMouseActionSoft({"HARVEST"}, ent)
        end)
        if not beebox then
            return Say("没有蜂箱")
        end
        if beebox:HasTag("fire") then
            d_util:SpaceScene(beebox, "HARVEST")
        else
            local item = p_util:GetItemFromAll(nil, nil, function(item)
                return p_util:GetAction("useitem", "LIGHT", true, item, beebox) or p_util:GetAction("useitem", "LIGHT", false, item, beebox)
            end)
            if not item then
                return Say("没有火炬")
            end
            if d_util:SpaceUseitem(item, beebox, "LIGHT", function(target)
                return not target:HasTag("fire")
            end) then
                return Say("无法点燃, 请联系开发者！")
            end
        end
        d_util:Wait()
    end, function()
        u_util:Say(str_auto, "结束")
    end)
end

local fn_right = m_util:AddBindShowScreen({
    title="火中取蜜 教程",
    id=save_id,
    data = {{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1DYUCB8EML", true)end
    },{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        type = "imgstr",
        label = "特别鸣谢",
        hover = "󰀍 特别鸣谢 󰀍",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", '火中取蜜功能由玩家"小宇"定制。\n\n留言："纯净档，小开不算开"', {{text = "󰀍"}})
        end
    },
    }
})


m_util:AddBindConf(save_id, fn_left, fn_left, {str_auto, img_show , STRINGS.LMB .. '启动/结束 ' .. STRINGS.RMB .. '教程演示'
, true, fn_left, fn_right, 5998})