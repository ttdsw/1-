
local save_id, str_auto, img_show = "sw_fishkill", "自动宰杀", "oceanfish_medium_8_inv"
local default_data = {
    cate = "all",
    pos = "all",
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)



local function fn_left()
    local pusher = m_util:GetPusher()
    if not pusher then return end
    
    local order = "mouse"
    local pos = save_data.pos
    if pos == "backpack" then
        order = {"backpack"}
    elseif order == "inv" then
        order = {"body"}
    elseif order == "player" then
        order = {"backpack", "body"}
    elseif order == "cont" then
        order = {"container"}
    end

    pusher:RegNowTask(function()
        local fish = p_util:GetItemFromAll(nil, nil, function(item)
            if p_util:GetAction("inv", "MURDER", true, item) then
                local cate, prefab = save_data.cate, item.prefab
                if table.contains({"pondfish", "pondeel"}, cate) then
                    return prefab == cate
                elseif table.contains({"oceanfish", "wobster"}, cate)then
                    return prefab:find(cate)
                elseif table.contains({"spider", "fish"}, cate) then
                    return item:HasTag(cate)
                end
                return true
            end
        end, order)
        if fish then
            local act = p_util:GetAction("inv", "MURDER", true, fish)
            if act then
                p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, fish, act.action.mod_name)
            end
        else
            return true
        end
        d_util:Wait()
    end, function()
        u_util:Say(str_auto, "结束")
    end)
end



local fn_right = m_util:AddBindShowScreen{
    title="自动宰杀 高级设置",
    id=save_id,
    data = {{
            id = "cate",
            type = "radio",
            label = "宰杀类别:",
            hover = "选择要宰杀哪些生物",
            data = {
                {description="所有生物", data="all"},
                {description="淡水鱼", data="pondfish"},
                {description="鳗鱼", data="pondeel"},
                {description="海鱼", data="oceanfish"},
                {description="鱼类", data="fish"},
                {description="蜘蛛类", data="spider"},
                {description="龙虾", data="wobster"},
            },
            fn = fn_save("cate"),
            default = fn_get,
        },{
            id = "pos",
            type = "radio",
            label = "宰杀区域:",
            hover = "选择要宰杀哪些位置",
            data = {
                {description="所有位置", data="all"},
                {description="仅背包", data="backpack"},
                {description="仅物品栏", data="inv"},
                {description="背包+物品栏", data="player"},
                {description="仅容器", data="cont"},
            },
            fn = fn_save("pos"),
            default = fn_get,
        },
    },
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", '自动宰杀功能由玩家"小宇"定制。\n\n留言："纯净档，小开不算开"', {{text = "󰀍"}})
        end,
    }}
}


m_util:AddBindConf(save_id, fn_left, fn_left, {str_auto, img_show , STRINGS.LMB .. '启动 ' .. STRINGS.RMB .. '高级设置'
, true, fn_left, fn_right})