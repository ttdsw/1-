
local save_id, str_show, logo = "sw_drop", "按键丢弃", "boomerang_bandedwood"
local prefab_umb = "voidcloth_umbrella"
local default_data = {
    sw = m_util:IsHuxi(),
    todrop_key = 122,
    sculp = true,
    range = 4,
    list_drop = {
        {prefab = prefab_umb, find = false, num = 1},
        {prefab = "canary_poisoned", find = true, prefabs = {"toadstool_cap"}, num = 1},
        {prefab = "birdtrap", find = false, prefabs = {}, num = 1},
        {prefab = "seeds", find = true, prefabs = {"birdtrap"}, num = 1},
        {prefab = "heatrock", find = true, prefabs = {"dragonflyfurnace", "stafflight", "staffcoldlight","moonbase","fire","lava_pond"}, num = 1},
        {prefab = "trap", find = true, prefabs = {"rabbithole", "rabbit"}, num = 1},
        {prefab = "lantern", find = false, prefabs = {}, num = 1},
        {prefab = "lightbulb", find = false, prefabs = {}, num = 1},
        {prefab = "thurible", find = true, prefabs = {"stalker_atrium", "stalker_forest", "stalker"}, num = 1},
    },
    umb = true,
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function fn_item()
    if save_data.sculp then
        local item = t_util:GetElement(p_util:GetEquips() or {}, function(_, it)
            return it and it:HasTag("heavy") and it
        end)
        if item then
            return {item = item, num = 1}
        end
    end
    local prefabs = t_util:IPairFilter(save_data.list_drop, function(data)
        return data.prefab
    end)
    local data = p_util:GetSlotsFromAll(prefabs) or {}
    return t_util:IGetElement(save_data.list_drop, function(dropdata)
        local prefab = dropdata.prefab
        local line = t_util:IGetElement(data, function(line)
            return line.item.prefab == prefab and line
        end)
        if line then
            if not dropdata.find or e_util:FindEnt(nil, dropdata.prefabs or {}, save_data.range, nil, {'INLIMBO', 'player'}) then
                return t_util:MergeMap(line, {num = dropdata.num})
            end
        end
    end)
end

local function fn_press()
    if not save_data.sw then return end
    local data = fn_item()
    if not data then return end
    if data.num == 1 then
        p_util:DropItemFromInvTile(data.item, true)
    elseif data.num == 0 then
        p_util:DropItemFromInvTile(data.item)
    elseif type(data.num) == "number" then
        p_util:TakeActiveItemFromCountOfSlot(data.cont, data.slot, data.num)
        e_util:WaitToDo(ThePlayer, .1, 10, function()
            return p_util:GetActiveItem(data.item.prefab)
        end, function()
            local item_active = p_util:GetActiveItem()
            if item_active then
                local pos = ThePlayer:GetPosition()
                local act = BufferedAction(ThePlayer, nil, ACTIONS.DROP, item_active, pos)
                act.options.wholestack = true
                p_util:DoAction(act, RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true)
            end
        end)
    end
    if data.item.prefab == prefab_umb and save_data.umb then
        e_util:WaitToDo(ThePlayer, .1, 10, function()
            return e_util:FindEnt(nil, prefab_umb, 1)
        end, function(umb)
            local act, right = p_util:GetMouseActionSoft({"TURNON"}, umb)
            if act then
                p_util:DoMouseAction(act, right)
            end
        end)
    end
end

local screen_data = {
    {
        id = "sw",
        label = "总开关",
        hover = "【按键丢弃】功能总开关",
        default = fn_get,
        fn = fn_save("sw"),
    },r_util:ScreenPack(save_data, fn_get, fn_save, fn_press, "todrop_key", "按键丢弃"),{
        id = "range",
        label = "检查范围：",
        hover = "搜索周围的物品范围，用于检查周围某些实体存在时才会丢弃",
        type = "radio",
        default = fn_get,
        fn = fn_save("range"),
        data = t_util:BuildNumInsert(1, 20, 1, function(i)
            return {data = i, description = i.." 墙点"}
        end)
    },
    {
        id = "sculp",
        label = "丢弃雕像",
        hover = "背着重物时是否按键丢弃雕像",
        default = fn_get,
        fn = fn_save("sculp"),
    },{
        id = "umb",
        label = "打开暗影伞",
        hover = "丢弃暗影伞后会自动打开",
        default = fn_get,
        fn = fn_save("umb"),
    },{
        id = "reset",
        type = "imgstr",
        label = "重置列表",
        prefab = logo,
        hover = "点击重置按键丢弃的物品！",
        fn = function()
            h_util:CreatePopupWithClose("警告", "你确定要重置按键丢弃物品的列表吗？\n一旦确认不可撤销！", {
                {
                    text = h_util.no,
                },{
                    text = h_util.yes,
                    cb = function()
                        
                        save_data.list_drop = {}
                        t_util:EasyCopy(save_data.list_drop, default_data.list_drop)
                        fn_save()
                        h_util:PlaySound("learn_map")
                    end
                }
            })
        end
    },
}
local function fn_prefab_data(data_drop)
    return function()
        local ret1 = {
            {
                id = "num",
                label = "丢弃数量：",
                hover = "丢弃单个或整组都是直接丢，\n其他数量会拿到鼠标上再丢",
                type = "radio",
                default = data_drop.num or 0,
                data = t_util:BuildNumInsert(0, 40, 1, function(i)
                    if i == 0 then
                        return {data = i, description = "丢弃整组"}
                    elseif i == 1 then
                        return {data = i, description = "丢弃单个"}
                    else
                        return {data = i, description = i.." 个"}
                    end
                end),
                fn = function(value)
                    data_drop.num = value
                    fn_save()
                end
            },{
                id = "find",
                label = "范围检查",
                hover = "启用此项：当周围存在之后设定的物品时，才丢弃\n禁用此项：直接丢弃",
                default = data_drop.find,
                fn = function(value)
                    data_drop.find = value
                    fn_save()
                end
            }
        }
        local ret2 = t_util:IPairFilter(data_drop.prefabs or {}, function(prefab)
            local name = e_util:GetPrefabName(prefab)
            name = name == e_util.NullName and prefab or name
            local data = {
                id = prefab, 
                fn = function()
                    h_util:CreatePopupWithClose(str_show.."："..name, "你确定要范围检查时不再检查此物品吗？", {{
                        text = h_util.no
                    }, {
                        text = "确定移除",
                        cb = function()
                            t_util:Sub(data_drop.prefabs or {}, prefab)
                            fn_save()
                        end
                    }})
                end
            }
            local str = c_util:TruncateChineseString(name, 10)
            if h_util:GetPrefabAsset(prefab) then
                data.type = "imgstr"
                data.label = str
                data.hover = "物品代码：" .. prefab .. "\n点击移除该物品！"
                data.prefab = prefab
            else
                data.type = "textbtn"
                data.default = str
                data.label = "模组物品："
                data.hover = "该物品为模组物品，无法显示图标".."\n点击移除该物品！"
            end
            return data
        end)
        return t_util:MergeList(ret1, ret2)
    end
end

local function fn_remove(prefab, name)
    return function()
        h_util:CreatePopupWithClose(str_show.."："..name, "你确定不再按键丢弃此物品吗？", {{
            text = h_util.no
        }, {
            text = "确定移除",
            cb = function()
                save_data.list_drop = t_util:IPairFilter(save_data.list_drop, function(data_drop)
                    return data_drop.prefab ~= prefab and data_drop
                end)
                fn_save()
                TheFrontEnd:PopScreen()
            end
        }})
    end
end
local function fn_ing_add(data_drop, name_item)
    return function()
        m_util:PushPrefabScreen{
            text_title = "选择丢弃"..name_item.."时的范围检查的物品",
            text_btnok = "添加物品",
            hover_btnok = "丢弃时检查此物品",
            fn_btnok = function(prefab)
                if table.contains(data_drop.prefabs or {}, prefab) then
                    h_util:CreatePopupWithClose("重复添加", "该物品已经在清单了, 还请添加别的物品。")
                else
                    t_util:Add(data_drop.prefabs, prefab, true)
                    fn_save()
                end
            end
        }
    end
end

local function fn_get_screen_data()
    local ui_data = t_util:IPairFilter(save_data.list_drop, function(data_drop)
        local prefab = data_drop.prefab
        local name = e_util:GetPrefabName(prefab)
        name = name == e_util.NullName and prefab or name
        local data = {
            id = prefab, 
            fn = m_util:AddBindShowScreen{
                id = save_id.."_"..prefab,
                title = str_show.." "..name,
                help = "未启用范围检查时：直接丢弃。\n启用范围检查：必须要有范围内有设定的物品才会丢弃。",
                data = fn_prefab_data(data_drop),
                fn_active = true,
                dontpop = true,
                icon = {
                    {
                        id = "remove",
                        prefab = "clean_all",
                        hover = "移除该物品！",
                        fn = fn_remove(prefab, name),
                    },{
                        id = "add",
                        prefab = "mods",
                        hover = "添加范围检查物品",
                        fn = fn_ing_add(data_drop, name),
                    }
                },
            }
        }
        local str = c_util:TruncateChineseString(name, 10)
        if h_util:GetPrefabAsset(prefab) then
            data.type = "imgstr"
            data.label = str
            data.hover = "物品代码：" .. prefab .. "\n点击设置该物品！"
            data.prefab = prefab
        else
            data.type = "textbtn"
            data.default = str
            data.label = "模组物品："
            data.hover = "该物品为模组物品，无法显示图标".."\n点击设置该物品！"
        end
        return data
    end)

    return t_util:MergeList(screen_data, ui_data)
end

local function fn_add()
    return m_util:PushPrefabScreen{
        text_title = "选择按键丢弃的物品",
        text_btnok = "添加物品",
        hover_btnok = "按键丢弃此物品",
        fn_btnok = function(prefab)
            if t_util:IGetElement(save_data.list_drop, function(data)
                return data.prefab == prefab
            end) then
                h_util:CreatePopupWithClose("重复添加", "该物品已经在清单了, 还请添加别的物品。")
            else
                t_util:Add(save_data.list_drop, {prefab = prefab, find = false, prefabs = {}, num = 0}, true)
                fn_save()
            end
        end
    }
end

m_util:AddBindShowScreen(save_id, str_show, logo, str_show.."的相关设置", {
    title = str_show,
    id = save_id,
    data = fn_get_screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀬 特别鸣谢 󰀬", '按键丢弃功能由玩家"隔壁の老怂"定制。\n\n留言："离远点！隔壁の老怂～～""我要开杀！"', {{text = "󰀬"}})
        end,
    },{
        id = "add",
        prefab = "mods",
        hover = "添加按键丢弃的物品",
        fn = fn_add,
    }},
    help = "先绑定按键，会根据顺序和条件依次丢弃物品。\n丢单个或一组都能直接丢，但是其他数量的话，需要腾鼠标。",
    fn_active = true,
}, nil, 8000.6)