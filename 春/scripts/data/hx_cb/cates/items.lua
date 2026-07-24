local g_util = require "util/fn_gallery"
local t_util = require "util/tableutil"

local cates = {{
        id = "all",
        icon = "filter_none",
        name = STRINGS.UI.COOKBOOK.FILTER_ALL,
        prefabs = g_util.items_all,
    }, 
    {
        id = "material",
        icon = "twigs",
        name = "材料"..g_util.str_seemore,
        prefabs = g_util.items_material,
        nosort = true,
        fn_rr = g_util.SeeMore("材料的排序", "材料的排序是根据所有配方用的材料数量统计排列, 开着不同的模组, 这里的顺序也不同。"),
    },{
        id = "prop",
        icon = "terrarium",
        name = "道具"..g_util.str_seemore,
        prefabs = g_util.items_prop,
        fn_rr = g_util.SeeMore("道具的定义", "能放到物品栏，不能被制作，不是材料、装备、食物、装饰、植物、可交易物品。"),
        hot = true,
    },{
        id = "plant",
        icon = "dug_sapling",
        name = "种植", 
        prefabs = g_util.items_plant,
    },
    
    
    
    
    
    
    {
        id = "trinket",
        icon = "trinket_4",
        name = t_util:GetRecur(STRINGS, "UI.TRADESCREEN.TRADE") or "交易",
        prefabs = g_util.items_trinket,
    },{
        id = "ornament",
        icon = "winter_ornament_light1",
        name = STRINGS.ACTIONS.DECORATEVASE or "装饰",
        prefabs = g_util.items_ornament,
    },{
        id = "turf",
        icon = "dock_kit",
        name = "地皮", 
        prefabs = g_util.items_turf,
    },{
        id = "wall",
        icon = "wall_stone_item",
        name = "墙", 
        prefabs = g_util.items_wall,
    },{
        id = "seafaring",
        icon = "steeringwheel",
        name = "航海",
        prefabs = g_util.items_seafaring,
    },{
        id = "eceanfishing",
        icon = "oceanfishinglure_hermit_heavy",
        name = "海钓",
        prefabs = g_util.items_fishing,
    },
}



return {
    default = "material",
    cates = cates,
}