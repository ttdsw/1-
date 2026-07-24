
local save_id, str_show, logo = "sw_autoeat", "自动吃饭", "icon_hunger"
local default_data = {
    sw_hunger = false,
    sw_health = false,
    value_hun = 0,
    value_hea = 0,
    prefab_hun = "shroomcake",
    prefab_hea = "vegstinger",
    sw_cont = true,
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local _lock_eat

i_util:AddPlayerActivatedFunc(function(player)
    local function AutoEat(prefab_food)
        if _lock_eat then
            return
        end
        local food = p_util:GetItemFromAll(prefab_food, nil, nil, "mouse")
        if food then
            p_util:Eat(food)
        elseif save_data.sw_cont and not p_util:GetActiveItem() then
            local cont = p_util:GetItemFromAll(nil, nil, function(ent)
                return not p_util:IsOpenContainer(ent) and Mod_ShroomMilk.Func.HasPrefabWithBox and Mod_ShroomMilk.Func.HasPrefabWithBox(ent, prefab_food, true)
            end, {"container", "backpack", "body",})
            if cont then
                local act = cont and p_util:GetAction("inv", "RUMMAGE", true, cont)
                if act then
                    _lock_eat = true
                    p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, cont)
                    e_util:WaitToDo(player, .1, 10, function()
                        return p_util:IsOpenContainer(cont)
                    end, function()
                        local food = p_util:GetItemFromAll(prefab_food, nil, nil, "mouse")
                        if food then
                            p_util:Eat(food)
                        else
                            act = cont and p_util:GetAction("inv", "RUMMAGE", true, cont)
                            if act then
                                p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, cont)
                            end
                        end
                        _lock_eat = nil
                    end, function()
                        _lock_eat = nil
                    end)
                end
            end
        end
    end
    local function InHunger()
        return save_data.sw_hunger and t_util:GetRecur(player, "replica.hunger") and player.replica.hunger:GetCurrent() <= save_data.value_hun
    end
    local function InHealth()
        return save_data.sw_health and t_util:GetRecur(player, "replica.health") and player.replica.health:GetCurrent() <= save_data.value_hea
    end
    player:ListenForEvent("hungerdelta", function()
        if InHunger() then
            AutoEat(save_data.prefab_hun)
        end
    end)
    player:ListenForEvent("healthdelta", function()
        if InHunger() then
            AutoEat(save_data.prefab_hun)
        elseif InHealth() then
            AutoEat(save_data.prefab_hea)
        end
    end)
end)

local function fn_textbtn(val_id, label, hover)
    return {
        id = val_id,
        label = label,
        hover = hover,
        default = fn_get,
        type = "textbtn",
        fn = function()
            h_util:CreateWriteWithClose("请输入玩家"..label, {
                text = "确认",
                cb = function(str)
                    local val = tonumber(str)
                    if val and val>=0 then
                        fn_save(val_id)(val)
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入大于等于 0 的数字哦。")
                    end
                end
            })
        end
    }
end
local screen_data = {
    {
        id = "sw_hunger",
        label = "监听饥饿",
        hover = "启用此项时，将在低饥饿时自动干饭",
        default = fn_get,
        fn = fn_save("sw_hunger"),
    },
    fn_textbtn("value_hun", "饥饿下限：", "饥饿值低于或等于此数值时，将自动干饭"),
    {
        id = "sw_health",
        label = "监听生命",
        hover = "启用此项时，将在低血量时自动干饭",
        default = fn_get,
        fn = fn_save("sw_health"),
    },
    fn_textbtn("value_hea", "生命下限：", "生命值低于或等于此数值时，将自动干饭"),
}
local function fn_set_prefab(pid, title, prefix)
    local prefab = save_data[pid] or default_data[pid]
    local name = e_util:GetPrefabName(prefab)
    name = name == e_util.NullName and prefab or name
    local data = {
        id = prefab, 
        fn = function()
            m_util:PushPrefabScreen{
                text_title = title,
                text_btnok = "确认选择",
                hover_btnok = "确认自动吃掉",
                fn_btnok = function(prefab)
                    fn_save(pid)(prefab)
                end
            }
        end
    }
    local str = c_util:TruncateChineseString(prefix..name, 10)
    if h_util:GetPrefabAsset(prefab) then
        data.type = "imgstr"
        data.label = str
        data.hover = prefix .. name .. "\n点击修改食物！"
        data.prefab = prefab
    else
        data.type = "textbtn"
        data.default = str
        data.label = prefix
        data.hover = "该食物为模组物品，无法显示图标".."\n点击修改食物！"
    end
    return data
end

local function fn_get_screen_data()
    local ui_data = {
    {
        id = "sw_cont",
        label = "开罐查找",
        hover = "是否允许打开极地熊罐桶等容器寻找食物",
        default = fn_get,
        fn = fn_save("sw_cont"),
    },}
    table.insert(ui_data, 1, fn_set_prefab("prefab_hea", "选择低血量吃掉的料理", "低生命吃："))
    table.insert(ui_data, 1, fn_set_prefab("prefab_hun", "选择低饱食吃掉的料理", "饥饿时吃："))
    return t_util:MergeList(screen_data, ui_data)
end
m_util:AddBindShowScreen(save_id, str_show, logo, str_show.." 的相关设置", {
    title = str_show,
    id = save_id,
    data = fn_get_screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀎 特别鸣谢 󰀎", '自动吃饭功能由玩家"忆往昔"定制。\n\n留言："饿了么"', {{text = "󰀎"}})
        end,
    }},
    help = "此功能用于全自动挂机，并不推荐日常游玩时开启。",
    fn_active = true,
})