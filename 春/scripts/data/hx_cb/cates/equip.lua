local g_util = require "util/fn_gallery"
local m_util = require "util/modutil"
local h_util = require "util/hudutil"
local save_data = require("util/fn_hxcb").save_data
local i_util = require "util/inpututil"
local t_util = require "util/tableutil"


local cates = {
    {
        id = "all",
        icon = "filter_none",
        name = "所有"..g_util.str_seemore,
        prefabs = g_util.equip_all,
        fn_rr = g_util.SeeMore("关于装备", "如果在右侧分类中找不到所需装备，请在【全部】标签内刷一个出来，\n手动装备后，数据就会记录在此"),
        hot = true,
    },
    {
        id = "hands",
        icon = "eslot_hands",
        name = "手持",
        prefabs = g_util.equip_eslot("hands"),
        hot = true,
    },
    {
        id = "body",
        icon = "eslot_body",
        name = "身穿",
        prefabs = function()
            local prefabs = g_util.equip_eslot("body")()
            return t_util:SubIPairs(g_util.equip_costume(), prefabs)
        end,
        hot = true,
    },
    {
        id = "head",
        icon = "strawhat",
        name = "头戴",
        prefabs = function()
            local prefabs = g_util.equip_eslot("head")()
            return t_util:SubIPairs(g_util.equip_costume(), prefabs)
        end,
        hot = true,
    },
    {
        id = "sculp",
        icon = "potato_oversized_waxed",
        name = "重物",
        prefabs = g_util.equip_eslot("sculp")
    },
    {
        id = "costume",
        icon = "mask_dollhat",
        name = "戏服",
        prefabs = g_util.equip_costume
    },
    {
        id = "armor",
        icon = "armorwood",
        name = "护甲",
        prefabs = g_util.equip_armor
    },
    {
        id = "weapon",
        icon = "hambat",
        name = "武器",
        prefabs = g_util.equip_weapon
    },
    {
        id = "tool",
        icon = "axe",
        name = "工具",
        prefabs = g_util.equip_tool
    },
    {
        id = "backpack",
        icon = "backpack",
        name = "背包",
        prefabs = g_util.equip_backpack
    },
    {
        id = "clothing",
        icon = "trunkvest_winter",
        name = "服装",
        prefabs = g_util.equip_clothing
    },
    {
        id = "hat",
        icon = "winterhat",
        name = "帽子",
        prefabs = g_util.equip_hat
    },
}

if save_data.equipmem then
    table.insert(cates, 6,
    {
        id = "memory",
        icon = "slurper",
        name = "记忆"..g_util.str_seemore,
        prefabs = g_util.equip_memory,
        fn_rr = function()
            h_util:CreatePopupWithClose("关于记忆", "当你装备一些不在列表中的装备,比如测试服或者模组装备时,\n它们的数据会自动保存在这里。", {
                {text = "清理记忆", cb = function()
                    i_util:DoTaskInTime(.1, g_util.equip_clear)
                end},
                {text = h_util.ok},
            })
        end
    })
end
table.insert(cates, 
    {
        id = "sew",
        icon = "sewing_kit",
        name = "修复材料"..g_util.str_seemore,
        prefabs = g_util.equip_sew,
        fn_rr = g_util.SeeMore("功能联动", "【自动修复】功能所用的修复材料，也会在这里出现。")
    })


if m_util:IsMilker() and false then
    table.insert(cates, {
        id = "error",
        icon = "fused_shadeling_bomb",
        name = "崩溃",
        prefabs = g_util.equip_eslot("error")
    })
end


return {
    default = "hands",
    cates = cates,
}