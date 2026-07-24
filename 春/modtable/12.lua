local id_per_last, logo = "_unequip_lastperc", "yellowamulet"
local save_id, str_show = "sw_hjsl_unequip", "装备脱落"
local list_one = {"molehat", "featherhat", "tophat", "walterhat", "goggleshat", "deserthat", "moonstorm_goggleshat",
                  "catcoonhat", "earmuffshat", "winterhat", "walrushat", "beefalohat", "strawhat", "eyebrellahat",
                  "trunkvest_summer", "raincoat", "sweatervest", "trunkvest_winter", "beargervest", "armorslurper",
                  "carnival_vest_b", "carnival_vest_c", "monkey_mediumhat", "monkey_smallhat", "antlionhat",
                  "nightcaphat"}
local default_data = {
    color_say = "粉色",
    sw = true,
    list = {
        eyemaskhat = 12,
        shieldofterror = 12,
        armordreadstone = 6,
        dreadstonehat = 6,
        orangeamulet = 3,
        yellowamulet = 3,
        shadow_battleaxe = 3
    }
}
t_util:IPairs(list_one, function(prefab)
    default_data.list[prefab] = 1
end)

local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function NeedAutoUnEquip(equip)
    local prefab = equip and equip.prefab
    local per_now = e_util:GetPercent(equip)
    if save_data.sw and prefab and per_now then
        local per_num = save_data.list[prefab]
        return type(per_num) == "number" and per_num >= per_now and equip
    end
end
i_util:AddPlayerActivatedFunc(function(player, world, pusher)
    
    local function listen_unequip(equip)
        local slot = e_util:GetItemEquipSlot(equip)
        
        local per_now = e_util:GetPercent(equip)
        if slot and p_util:GetEquip(slot) == equip then
            local per_last = equip[id_per_last]
            local prefab = equip.prefab
            
            if type(per_last) == "number" and per_last > per_now then
                if NeedAutoUnEquip(equip) then
                    p_util:UnEquip(equip)
                    local slot = e_util:GetItemEquipSlot(equip)
                    e_util:WaitToDo(player, 0.1, 20, function()
                        if equip == p_util:GetEquip(slot) then
                            p_util:UnEquip(equip)
                        else
                            return true
                        end
                    end)
                    u_util:Say(str_show, equip.name, nil, save_data.color_say)
                end
            end
        end
        equip[id_per_last] = per_now
    end
    
    pusher:RegEquip(function(_, equip)
        e_util:SetBindEvent(equip, "percentusedchange", listen_unequip)
        equip[id_per_last] = e_util:GetPercent(equip)
    end)
end)

local function fn_equip(prefab)
    h_util:CreateWriteWithClose("请输入耐久百分比(1-100):", {
        text = "确认",
        cb = function(str)
            local num = tonumber(str)
            if num and num >= 1 and num <= 100 and num % 1 == 0 then
                save_data.list[prefab] = num
                fn_save()
            else
                h_util:CreatePopupWithClose("不行的", "要输入 1-100 的整数哦。")
            end
        end
    })
end

local function fn_add()
    m_util:PushPrefabScreen{
        text_title = "选择要自动脱落的装备",
        text_btnok = "设置耐久",
        hover_btnok = "添加该装备到" .. str_show .. "列表",
        fn_btnok = function(prefab)
            if save_data.list[prefab] then
                h_util:CreatePopupWithClose("重复添加", "该装备已经在" .. str_show ..
                    "列表中,\n还请添加别的装备。")
            else
                fn_equip(prefab)
            end
        end
    }
end

local function fn_list()
    
    local pdata = t_util:PairToIPair(save_data.list, function(prefab, num)
        return type(num) == "number" and {
            prefab = prefab,
            num = num
        }
    end)
    table.sort(pdata, function(a, b)
        return a.num > b.num
    end)
    return t_util:IPairToIPair(pdata, function(info)
        local prefab = info.prefab
        local name = e_util:GetPrefabName(prefab)
        name = name == e_util.NullName and prefab or name
        local data = {
            id = prefab,
            fn = function()
                h_util:CreatePopupWithClose(str_show .. "：" .. name,
                    "你确定要移除该装备的自动脱落吗？\n(当前耐久低于或等于 " .. info.num ..
                        "% 时自动脱落)", {{
                        text = h_util.no
                    }, {
                        text = "修改耐久",
                        cb = function()
                            i_util:DoTaskInTime(0, function()
                                fn_equip(prefab)
                            end)
                        end
                    }, {
                        text = "确定移除",
                        cb = function()
                            save_data.list[prefab] = nil
                            fn_save()
                        end
                    }})
            end
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
            data.label = "模组装备："
            data.hover = "该物品为模组物品，无法显示图标" .. "\n点击修改设置！"
        end
        return data
    end)
end

local screen_data = {{
    id = "sw",
    label = "总开关",
    fn = fn_save("sw"),
    hover = "装备脱落的总开关",
    default = fn_get
}, {
    id = "color_say",
    label = "提示颜色：",
    fn = fn_save("color_say"),
    hover = "装备脱落后提示的颜色",
    default = fn_get,
    type = "radio",
    data = require("data/valuetable").RGB_datatable
}, {
    id = "reset",
    type = "imgstr",
    prefab = "moonrockseed",
    hover = "恢复默认的装备列表",
    label = "重置装备列表",
    fn = function()
        h_util:CreatePopupWithClose("警告",
            "你确定要恢复默认设置的脱落装备列表吗？\n这将覆盖原来的设置！", {{
                text = h_util.no
            }, {
                text = h_util.yes,
                cb = function()
                    
                    save_data.list = t_util:MergeMap(default_data.list)
                    fn_save()
                    h_util:PlaySound("learn_map")
                end
            }})
    end
}, {
    id = "list",
    type = "imgstr",
    prefab = logo,
    hover = STRINGS.LMB .. "查看脱落装备列表",
    label = "设置脱落装备",
    fn = m_util:AddBindShowScreen{
        title = "装备脱落清单",
        id = save_id .. "_list",
        data = fn_list,
        help = "当装备耐久低于或等于设定值时，自动脱落该装备。\n点击右侧扳手按钮可添加装备，点击下方物品名移除该装备的自动脱落。",
        fn_active = true,
        dontpop = true,
        icon = {{
            id = "add",
            prefab = "mods",
            hover = "添加要自动脱落的装备！",
            fn = fn_add
        }}
    }
}}

m_util:AddBindShowScreen(save_id, str_show, logo, "装备脱落的相关设置", {
    title = str_show,
    id = save_id,
    data = screen_data,
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", "本模组功能由金主 花间随柳 定制。", {{
                text = "󰀍"
            }})
        end
    }}
}, nil, 8000.9)

Mod_ShroomMilk.Func.NeedAutoUnEquip = NeedAutoUnEquip
