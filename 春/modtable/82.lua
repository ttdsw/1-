local id_per_last, logo = "_repair_lastperc", "orangeamulet"
local save_id, str_show = "sw_hjsl_repair", "自动修复"
local default_data = {
    sw = true,
    list = {
        lantern = {num = 25, ing = {"lightbulb"}},
        lighter = {num = 25, ing = {"willow_ember"}},
        minerhat = {num = 25, ing = {"lightbulb"}},
        molehat = {num = 25, ing = {"wormlight_lesser", "wormlight"}},
        thurible = {num = 25, ing = {"nightmarefuel"}},
        armorskeleton = {num = 25, ing = {"nightmarefuel"}},
        orangeamulet = {num = 25, ing = {"nightmarefuel"}},
        yellowamulet = {num = 25, ing = {"nightmarefuel"}},
        waxwelljournal = {num = 25, ing = {"nightmarefuel"}, force = true},
        pocketwatch_weapon = {num = 12, ing = {"nightmarefuel"}},
    }
}

local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function RepairNow(item, items)
    local data = t_util:IGetElement(items, function(useitem)
        if item == useitem then return end
        
        
        local act = p_util:GetAction("useitem", nil, true, useitem, item)
        return act and act.action and { act = act, useitem = useitem }
    end)
    if data then
        p_util:DoAction(data.act, RPC.ControllerUseItemOnItemFromInvTile, data.act.action.code, item, data.useitem, data.act.action.mod_name)
    end
end



local Lock = {}
local function TryAutoRepair(item, per_now)
    local prefab = item and item.prefab
    local line = prefab and save_data.list[prefab] or {}
    per_now = per_now or e_util:GetPercent(item)
    if type(line) == "table" and type(line.num)=="number" and line.num >= per_now then
        local items = p_util:GetItemsFromAll(line.ing or {}) or {}
        if items[1] then
            RepairNow(item, items)
            if line.force and not Lock[item] then
                Lock[item] = true
                e_util:WaitToDo(item, 1, 10, function()
                    if e_util:GetPercent(item) > per_now then
                        return true
                    end
                    RepairNow(item, items)
                end, function()
                    m_util:print("修复成功！")
                    Lock[item] = nil
                end, function()
                    m_util:print("修复失败，放弃！")
                    Lock[item] = nil
                end)
            end
        end
    end
end

local function listen_repair(item)
    
    local per_now = e_util:GetPercent(item)
    local per_last = item[id_per_last]
    
    if save_data.sw and type(per_last) == "number" and per_last > per_now then
        TryAutoRepair(item, per_now)
    end
    item[id_per_last] = per_now
end
i_util:AddPlayerActivatedFunc(function(player, world, pusher)
    
    pusher:RegAddInv(function(cont, slot, item)
        e_util:SetBindEvent(item, "percentusedchange", listen_repair)
        item[id_per_last] = e_util:GetPercent(item)
    end)
    pusher:RegDeleteInv(function(cont, slot, item)
        item:RemoveEventCallback("percentusedchange", listen_repair)
    end)
end)

local function fn_item(prefab)
    h_util:CreateWriteWithClose("请输入耐久百分比(1-100):", {
        text = "确认",
        cb = function(str)
            local num = tonumber(str)
            if num and num >= 1 and num <= 100 and num % 1 == 0 then
                if not save_data.list[prefab] then
                    save_data.list[prefab] = {num = num, ing = {"nightmarefuel"}}
                else
                    save_data.list[prefab].num = num
                end
                fn_save()
            else
                h_util:CreatePopupWithClose("不行的", "要输入 1-100 的整数哦。")
            end
        end
    })
end

local function fn_add()
    m_util:PushPrefabScreen{
        text_title = "选择要自动修复的物品",
        text_btnok = "添加物品",
        hover_btnok = "添加该物品到"..str_show.."列表",
        fn_btnok = function(prefab)
            if save_data.list[prefab] then
                h_util:CreatePopupWithClose("重复添加", "该物品已经在"..str_show.."列表中，\n还请添加别的物品。")
            else
                
                save_data.list[prefab] = {num = 5, ing = {"nightmarefuel"}}
                fn_save()
            end
        end,
    }
end
local function fn_ing(info, name_item)
    return function()
        local line = save_data.list[info.prefab] or {}
        local num = line.num or 5
        local list_per = {
            {
                id = "setitempercent",
                type = "textbtn",
                label = "修复耐久：",
                hover = "低于或等于此耐久时将使用后续材料修复\n"..STRINGS.LMB.."修改耐久",
                default = num.."%",
                fn = function()
                    fn_item(info.prefab)
                end
            },{
                id = "force",
                type = "box",
                label = "强制修复",
                hover = "是否强制修复该物品？\n(当前被别的动作硬控时，是否尝试一直修复)",
                default = line.force,
                fn = function(val)
                    line.force = val
                    fn_save()
                end
            }
        }
        local list_ing = t_util:IPairFilter(line.ing or {}, function(prefab)
            local name = e_util:GetPrefabName(prefab)
            local label = name == e_util.NullName and prefab or name
            local data = {}
            if h_util:GetPrefabAsset(prefab) then
                data.type = "imgstr"
                data.prefab = prefab
                data.label = label
            else
                data.type = "textbtn"
                data.label = "未知材料："
                data.default = label
            end
            return t_util:MergeMap({
                id = prefab,
                hover = "物品代码：" .. prefab .. "\n"..STRINGS.LMB.."不再使用此材料修复"..name_item,
                fn = function()
                    h_util:CreatePopupWithClose(str_show, "你确定不再使用 " .. label .. " 修复"..name_item.."吗？",
                        {{
                            text = h_util.no
                        }, {
                            text = h_util.yes,
                            cb = function()
                                local line = save_data.list[info.prefab]
                                local ings = line and line.ing or {}
                                t_util:Sub(ings, prefab)
                                fn_save()
                            end
                        }})
                end
            }, data)
        end)
        return t_util:MergeList(list_per, list_ing)
    end
end
local function fn_ing_add(info, name_item)
    return function()
        m_util:PushPrefabScreen{
            text_title = "选择用来修复"..name_item.."的材料",
            text_btnok = "添加材料",
            hover_btnok = "使用该材料修复"..name_item,
            fn_btnok = function(prefab)
                local line = save_data.list[info.prefab] or {}
                local ing = line.ing or {}
                if table.contains(ing, prefab) then
                    h_util:CreatePopupWithClose("重复添加", "该材料添加过了, 还请添加别的材料。")
                else
                    t_util:Add(ing, prefab)
                    fn_save()
                end
            end
        }
    end
end
local function fn_remove(prefab, name, num)
    return function()
        h_util:CreatePopupWithClose(str_show.."："..name, "你确定不再对该物品自动修复吗？\n(当前耐久低于或等于 "..num.."% 时自动修复)", {{
                text = h_util.no
            }, {
                text = "确定移除",
                cb = function()
                    save_data.list[prefab] = nil
                    fn_save()
                    TheFrontEnd:PopScreen()
                end
            }})
    end
end

local function fn_list()
    
    local pdata = t_util:PairToIPair(save_data.list, function(prefab, line)
        return type(line) == "table" and {prefab = prefab, num = line.num, ing = line.ing}
    end)
    table.sort(pdata, function(a, b)
        return a.num < b.num
    end)
    return t_util:IPairToIPair(pdata, function(info)
        local prefab = info.prefab
        local name = e_util:GetPrefabName(prefab)
        name = name == e_util.NullName and prefab or name
        local data = {id = prefab, fn = m_util:AddBindShowScreen{
            title = name.." 所用材料",
            id = save_id.."_"..prefab,
            data = fn_ing(info, name),
            help = "当物品耐久低于或等于设定值时，使用下列材料修复该物品。\n点击右侧扳手按钮可添加材料，右侧扫把按钮移除该物品的自动修复。",
            fn_active = true,
            dontpop = true,
            icon = {{
                id = "remove",
                prefab = "clean_all",
                hover = "移除该物品！",
                fn = fn_remove(prefab, name, info.num),
            },{
                id = "add",
                prefab = "mods",
                hover = "添加修复所用材料",
                fn = fn_ing_add(info, name),
            }}
        }}
        local str = c_util:TruncateChineseString(info.num.."% "..name, 10)
        if h_util:GetPrefabAsset(prefab) then
            data.type = "imgstr"
            data.label = str
            data.hover = "物品代码：" .. prefab .. "\n点击修改设置！"
            data.prefab = prefab
        else
            data.type = "textbtn"
            data.default = str
            data.label = "模组物品："
            data.hover = "该物品为模组物品，无法显示图标".."\n点击修改设置！"
        end
        return data
    end)
end

local screen_data = {{
    id = "sw",
    label = "总开关",
    fn = fn_save("sw"),
    hover = "自动修复的总开关",
    default = fn_get
}, {
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1czygBkENd/", true)end
    },{
    id = "reset",
    type = "imgstr",
    prefab = "moonrockseed",
    hover = "恢复默认的物品列表",
    label = "重置物品列表",
    fn = function()
        h_util:CreatePopupWithClose("警告",
            "你确定要恢复默认设置的物品列表吗？\n这将覆盖原来的设置！", {{
                text = h_util.no
            }, {
                text = h_util.yes,
                cb = function()
                    
                    save_data.list = {}
                    t_util:EasyCopy(save_data.list, default_data.list)
                    fn_save()
                    h_util:PlaySound("learn_map")
                end
            }})
    end
}, {
    id = "list",
    type = "imgstr",
    prefab = logo,
    hover = STRINGS.LMB .. "查看修复物品列表",
    label = "设置修复物品",
    fn = m_util:AddBindShowScreen{
        title = "自动修复清单",
        id = save_id .. "_list",
        data = fn_list,
        help = "当物品耐久低于或等于设定值时，自动修复该物品。\n点击右侧扳手按钮可添加物品，点击下方物品名查看该物品高级设置。",
        fn_active = true,
        dontpop = true,
        icon = {{
            id = "add",
            prefab = "mods",
            hover = "点击添加要自动修复的物品！",
            fn = fn_add,
        }}
    }
}}

m_util:AddBindShowScreen(save_id, str_show, logo, str_show.."的相关设置", {
    title = str_show,
    id = save_id,
    data = screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", "本模组功能由金主 花间随柳 定制。", {{text = "󰀍"}})
        end
    }}
}, nil, 8000.8)

Mod_ShroomMilk.Func.TryAutoRepair = TryAutoRepair