local save_id, str_show, logo = "sw_jh_repair", "驯牛辅助", "beefalo"
local default_data = {
    sw = false,
    torepair_key = 118,
    jh_mount = true,
    color_say = "粉色",
    jh_say = true,
    jh_bell = true,
    jh_feed = true,
    list_feed = {"lightbulb", "petals", "rock_avocado_fruit_ripe", "beefalofeed", "beefalotreat"}
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function Say(str1, str2)
    if not save_data.jh_say then return end
    u_util:Say(str1, str2, "head", save_data.color_say, true)
end


local function fn_to_mount()
    return e_util:FindEnt(nil, "beefalo", nil, nil, nil, nil, nil, function(ent)
        local act, right = p_util:GetMouseActionSoft({"MOUNT"}, ent)
        if act then
            
            if p_util:GetMouseActionSoft({"TOSS"}, ent) and not TheWorld.ismastersim then
                p_util:UnEquip(p_util:GetEquip("hands"))
            end
            p_util:DoMouseAction(act, right)
            Say("寻找骑行", "󰀁")
            return true
        end
    end)
end
local function fn_to_unmount()
    local act, right = p_util:GetMouseActionSoft({"DISMOUNT"}, ThePlayer)
    if act then
        p_util:DoMouseAction(act, right)
        Say("下鞍步行", "󰀁")
    end
end

local function fn_to_bell()
    local bell = p_util:GetItemFromAll(nil, {"beefalo_targeter", "bell", "inlimbo"}, function(item)
        return not item:HasOneOfTags({"inuse_targeted", "nobundling"})
    end, "mouse")
    return bell and e_util:FindEnt(nil, "beefalo", nil, nil, nil, nil, nil, function(ent)
        local leader = e_util:GetLeaderTarget(ent)
        
        if not leader or not leader:HasTag("bell") then
            local act = p_util:GetAction("useitem", "USEITEMON", nil, bell, ent)
            if act then
                p_util:DoAction(act, RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, bell, ent)
                Say("铃铛绑定", "󰀁")
                return true
            end
        end
    end)
end


local function fn_feed()
    local act = p_util:GetAction("inv", "FEED", nil, p_util:GetActiveItem())
    if act then
        local name = t_util:GetRecur(act, "invobject.name")
        if type(name)=="string" then
            p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, act.invobject)
            Say(name, "󰀁")
            return true
        end
    end
end
local function fn_to_feed()
    if p_util:IsRider() then
        if p_util:GetActiveItem() then
            return fn_feed()
        else
            local data = p_util:GetSlotFromAll(save_data.list_feed)
            if data then
                p_util:TakeActiveItemFromCountOfSlot(data.cont, data.slot, 1)
                e_util:WaitToDo(ThePlayer, .1, 10, function() return p_util:GetActiveItem() end, fn_feed)
                return true
            end
        end
    end
end

local function fn_press()
    if not save_data.sw then return end
    
    if save_data.jh_mount and fn_to_mount() then
        return
    end
    
    if save_data.jh_bell and fn_to_bell() then
        return
    end
    
    if save_data.jh_feed then
        if save_data.jh_feed == "close" then
            return Say(str_show, "已完成")
        elseif save_data.jh_feed == "unmount" then
            return fn_to_unmount()
        elseif fn_to_feed() then
            return
        end
    end
    Say(str_show, "已完成")
end


local function fn_add_feed()
    m_util:PushPrefabScreen{
        text_title = "选择要使用的󰀁饲料",
        text_btnok = "添加饲料",
        hover_btnok = "添加该饲料到󰀁饲料列表",
        fn_btnok = function(prefab)
            if table.contains(save_data.list_feed, prefab) then
                h_util:CreatePopupWithClose("重复添加", "该物品已经在󰀁饲料列表中，\n还请添加别的物品。")
            else
                t_util:Add(save_data.list_feed, prefab, true)
                fn_save()
            end
        end,
    }
end



local fn_set_feed = m_util:AddBindShowScreen{
    title = "󰀁饲料清单",
    id = "list_feed",
    data = m_util:FuncListRemove(save_data, "list_feed", fn_save, function(name)
        return "󰀁饲料："..name
    end, "你确定不再使用该饲料喂养󰀁吗？", function(name, prefab)
        return "物品代码：" .. prefab .. "\n点击移除该饲料！"
    end, "该物品为模组物品，无法显示图标\n点击移除该饲料！"),
    help = "骑着󰀁时，按键使用下列饲料喂食󰀁。\n点击右侧扳手按钮可添加饲料，点击下方饲料名移除该饲料。",
    fn_active = true,
    dontpop = true,
    icon = {{
        id = "add_repair",
        prefab = "mods",
        hover = "点击添加要按键喂食的󰀁饲料！",
        fn = fn_add_feed,
    },{
        id = "reset_repair",
        prefab = "revert2",
        hover = "点击重置要按键喂食的󰀁饲料！",
        fn = m_util:FuncListReset(save_data, default_data, fn_save, "你确定要重置󰀁饲料的列表吗？", "list_feed"),
    }}
}



local screen_data = {
    {
        id = "sw",
        label = "总开关",
        hover = "【驯牛辅助】所有功能总开关",
        default = fn_get,
        fn = fn_save("sw"),
    },r_util:ScreenPack(save_data, fn_get, fn_save, fn_press, "torepair_key", "驯牛辅助"),{
        id = "jh_say",
        label = "开关:文字提示",
        hover = "是否在角色头上显示进行的功能",
        default = fn_get,
        fn = fn_save("jh_say"),
    },{
        id = "color_say",
        label = "提示颜色:",
        default = fn_get,
        type = "radio",
        data = require("data/valuetable").RGB_datatable,
        fn = fn_save("color_say"),
    },{
        id = "jh_repair",
        label = "开关:修复物品",
        hover = "【修复物品】的开关",
        default = fn_get,
        fn = fn_save("jh_repair"),
    },{
        id = "jh_mount",
        label = "开关:寻找骑行",
        hover = "按下按键后骑行最近的󰀁",
        default = fn_get,
        fn = fn_save("jh_mount"),
    },{
        id = "jh_bell",
        label = "开关:铃铛绑定",
        hover = "按下按键后用牛铃铛绑定最近的󰀁",
        default = fn_get,
        fn = fn_save("jh_bell"),
    },{
        id = "jh_feed",
        label = "骑牛动作：",
        hover = "骑行牛牛时，按下按键执行的动作",
        default = fn_get,
        type = "radio",
        fn = fn_save("jh_feed"),
        data = {
            {data = "feed", description = "喂食"},
            {data = "unmount", description = "下牛"},
            {data = "close", description = "关闭"},
        }
    },{
        id = "list_feed",
        type = "imgstr",
        prefab = "beefalotreat",
        hover = "需要将【骑牛动作】设置为【喂食】才能生效",
        label = "设置:喂食牛牛",
        fn = fn_set_feed,
    },
}

m_util:AddBindShowScreen(save_id, str_show, logo, str_show.."的相关设置", {
    title = str_show,
    id = save_id,
    data = screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀁 特别鸣谢 󰀁", "驯牛辅助功能由玩家'逆风'定制。\n\n留言：喂一下我的牛牛。", {{text = "󰀁"}})
        end,
    }},
    help = "包含如下功能并按顺序执行一项：\n1、按键骑行最近的󰀁；\n3、按键牛铃铛绑定；4、按键喂食骑着的󰀁"
}, nil, 8000.7)            