local save_id, str_show, logo = "sw_newrepair", "按键修复", "sewing_kit"
local str_repair = str_show
local default_data = {
    sw = m_util:IsHuxi(),
    torepair_key = 118,
    list_repair = {
        lantern = {
            num = 80,
            ing = {"lightbulb"}
        },
        lighter = {
            num = 80,
            ing = {"willow_ember"}
        },
        minerhat = {
            num = 80,
            ing = {"lightbulb"}
        },
        molehat = {
            num = 80,
            ing = {"wormlight_lesser", "wormlight"}
        },
        thurible = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        armorskeleton = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        orangeamulet = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        yellowamulet = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        waxwelljournal = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        pocketwatch_weapon = {
            num = 80,
            ing = {"nightmarefuel"}
        },
        shieldofterror = {
            num = 75,
            ing = {"monstermeat"}
        },
        eyemaskhat = {
            num = 75,
            ing = {"monstermeat"}
        },
        raincoat = {
            num = 49,
            ing = {"sewing_tape", "sewing_kit"}
        },
        eyebrellahat = {
            num = 20,
            ing = {"sewing_tape", "sewing_kit"}
        },
        walrushat = {
            num = 80,
            ing = {"sewing_tape", "sewing_kit"}
        },
        heatrock = {
            num = 49,
            ing = {"sewing_tape", "sewing_kit"}
        }
    },
    jh_say = true,
    color_say = "粉色"
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function Say(str1, str2)
    if not save_data.jh_say then
        return
    end
    u_util:Say(str1, str2, "head", save_data.color_say, true)
end

local function fn_to_repair()
    
    local items = p_util:GetItemsFromAll(nil, nil, nil, {"equip", "body", "container", "backpack"}) or {}
    local data = t_util:IGetElement(items, function(target)
        local line = save_data.list_repair[target.prefab]
        
        if line and e_util:GetPercent(target) <= line.num then
            return t_util:IGetElement(items, function(useitem)
                if target ~= useitem and table.contains(line.ing or {}, useitem.prefab) then
                    local act = p_util:GetAction("useitem", nil, true, useitem, target)
                    local id = act and act.action and act.action.id
                    local str = act and act.GetActionString and act:GetActionString()
                    return id and str and {
                        act = act,
                        item = useitem,
                        target = target,
                        str = str
                    }
                end
            end)
        end
    end)
    if data then
        p_util:DoAction(data.act, RPC.ControllerUseItemOnItemFromInvTile, data.act.action.code, data.target, data.item,
            data.act.action.mod_name)
        Say(data.item.name .. " " .. data.str .. " " .. data.target.name, e_util:GetPercent(data.target) .. "%")
        return true
    end
end

local function fn_press()
    if not save_data.sw then
        return
    end
    
    if fn_to_repair() then
        return
    end
    Say(str_show, "已完成")
end
local function fn_item(prefab)
    h_util:CreateWriteWithClose("请输入耐久百分比(1-100):", {
        text = "确认",
        cb = function(str)
            local num = tonumber(str)
            if num and num >= 1 and num <= 100 and num % 1 == 0 then
                if save_data.list_repair[prefab] then
                    save_data.list_repair[prefab].num = num
                else
                    save_data.list_repair[prefab] = {
                        num = num,
                        ing = {"nightmarefuel"}
                    }
                end
                fn_save()
            else
                h_util:CreatePopupWithClose("不行的", "要输入 1-100 的整数哦。")
            end
        end
    })
end

local function fn_ing(info, name_item)
    return function()
        local line = save_data.list_repair[info.prefab] or {}
        local num = line.num or 5
        local list_per = {{
            id = "setitempercent",
            type = "textbtn",
            label = "修复耐久：",
            hover = "不高于此耐久时按键将使用后续材料修复\n" .. STRINGS.LMB .. "修改耐久",
            default = num .. "%",
            fn = function()
                fn_item(info.prefab)
            end
        }}
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
                hover = "物品代码：" .. prefab .. "\n" .. STRINGS.LMB .. "不再使用此材料修复" .. name_item,
                fn = function()
                    h_util:CreatePopupWithClose(str_repair,
                        "你确定不再使用 " .. label .. " 修复" .. name_item .. "吗？", {{
                            text = h_util.no
                        }, {
                            text = h_util.yes,
                            cb = function()
                                local line = save_data.list_repair[info.prefab]
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

local function fn_remove(prefab, name, num)
    return function()
        h_util:CreatePopupWithClose(str_repair .. "：" .. name,
            "你确定不再对该物品按键修复吗？\n(当前耐久不高于 " .. num .. "% 时按键修复)", {{
                text = h_util.no
            }, {
                text = "确定移除",
                cb = function()
                    save_data.list_repair[prefab] = nil
                    fn_save()
                    TheFrontEnd:PopScreen()
                end
            }})
    end
end

local function fn_ing_add(info, name_item)
    return function()
        m_util:PushPrefabScreen{
            text_title = "选择用来修复" .. name_item .. "的材料",
            text_btnok = "添加材料",
            hover_btnok = "使用该材料按键修复" .. name_item,
            fn_btnok = function(prefab)
                local line = save_data.list_repair[info.prefab] or {}
                local ing = line.ing or {}
                if table.contains(ing, prefab) then
                    h_util:CreatePopupWithClose("重复添加", "该材料添加过了, 还请添加别的材料。")
                else
                    t_util:Add(ing, prefab, true)
                    fn_save()
                end
            end
        }
    end
end


local function fn_list_repair()
    
    local pdata = t_util:PairToIPair(save_data.list_repair, function(prefab, line)
        return type(line) == "table" and {
            prefab = prefab,
            num = line.num,
            ing = line.ing
        }
    end)
    table.sort(pdata, function(a, b)
        return a.num < b.num
    end)
    return t_util:IPairToIPair(pdata, function(info)
        local prefab = info.prefab
        local name = e_util:GetPrefabName(prefab)
        name = name == e_util.NullName and prefab or name
        local data = {
            id = prefab,
            fn = m_util:AddBindShowScreen{
                title = name .. " 所用材料",
                id = save_id .. "_" .. prefab,
                data = fn_ing(info, name),
                help = "当物品耐久不高于设定值时，按键使用下列材料修复该物品。\n点击右侧扳手按钮可添加材料，右侧扫把按钮移除该物品的按键修复。",
                fn_active = true,
                dontpop = true,
                icon = {{
                    id = "remove",
                    prefab = "clean_all",
                    hover = "移除该物品！",
                    fn = fn_remove(prefab, name, info.num)
                }, {
                    id = "add",
                    prefab = "mods",
                    hover = "添加修复所用材料",
                    fn = fn_ing_add(info, name)
                }}
            }
        }
        local str = c_util:TruncateChineseString(info.num .. "% " .. name, 10)
        if h_util:GetPrefabAsset(prefab) then
            data.type = "imgstr"
            data.label = str
            data.hover = "物品代码：" .. prefab .. "\n点击修改设置！"
            data.prefab = prefab
        else
            data.type = "textbtn"
            data.default = str
            data.label = "模组物品："
            data.hover = "该物品为模组物品，无法显示图标" .. "\n点击修改设置！"
        end
        return data
    end)
end


local function fn_add_repair()
    m_util:PushPrefabScreen{
        text_title = "选择要按键修复的物品",
        text_btnok = "添加物品",
        hover_btnok = "添加该物品到" .. str_repair .. "列表",
        fn_btnok = function(prefab)
            if save_data.list_repair[prefab] then
                h_util:CreatePopupWithClose("重复添加", "该物品已经在" .. str_repair ..
                    "列表中，\n还请添加别的物品。")
            else
                
                save_data.list_repair[prefab] = {
                    num = 80,
                    ing = {"nightmarefuel"}
                }
                fn_save()
            end
        end
    }
end


local fn_set_repair = m_util:AddBindShowScreen{
    title = "按键修复清单",
    id = "list_repair",
    data = fn_list_repair,
    help = "当物品耐久不高于或等于设定值时，按键修复该物品。\n点击右侧扳手按钮可添加物品，点击下方物品名查看该物品高级设置。",
    fn_active = true,
    dontpop = true,
    icon = {{
        id = "add_repair",
        prefab = "mods",
        hover = "点击添加要按键修复的物品！",
        fn = fn_add_repair
    }, {
        id = "reset_repair",
        prefab = "revert2",
        hover = "点击重置按键修复的物品！",
        fn = m_util:FuncListReset(save_data, default_data, fn_save,
            "你确定要重置按键修复物品的列表吗？", "list_repair")
    }}
}

local screen_data = {{
    id = "sw",
    label = "总开关",
    hover = "按键修复的总开关",
    default = fn_get,
    fn = fn_save("sw")
}, r_util:ScreenPack(save_data, fn_get, fn_save, fn_press, "torepair_key", "按键修复"), {
    id = "jh_say",
    label = "开关:文字提示",
    hover = "是否在角色头上显示进行的功能",
    default = fn_get,
    fn = fn_save("jh_say")
}, {
    id = "color_say",
    label = "提示颜色:",
    default = fn_get,
    type = "radio",
    data = require("data/valuetable").RGB_datatable,
    fn = fn_save("color_say")
}, {
    id = "list_repair",
    type = "imgstr",
    prefab = "sewing_tape",
    hover = STRINGS.LMB .. "查看修复物品列表",
    label = "设置:修复物品",
    fn = fn_set_repair
}}


m_util:AddBindShowScreen(save_id, str_show, logo, str_show .. "的相关设置", {
    title = str_show,
    id = save_id,
    data = screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍",
                "本功能由金主 '69年专业刮痧' 定制。\n\n留言：荒野有福啦。", {{
                    text = "󰀍"
                }})
        end
    }}
}, nil, 8000.8)
