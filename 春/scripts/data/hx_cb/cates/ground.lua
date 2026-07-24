local g_util = require "util/fn_gallery"
local cates = {
    {
        id = "all",
        icon = "filter_none",
        name = "所有",
        prefabs = g_util.ground_all,
    },
    {
        id = "craftingstation",
        icon = "researchlab2",
        name = "科技站", 
        prefabs = g_util.ground_lab,
    },{
        id = "wall",
        icon = "wall_stone_item",
        name = "墙体", 
        prefabs = g_util.ground_wall,
    },
    {
        id = "structure",
        icon = "firepit",
        name = "建筑",
        prefabs = g_util.ground_structure,
    },
    {
        id = "atrium",
        icon = "atrium_key",
        name = "远古",
        prefabs = g_util.ground_atrium,
    },
    {
        id = "plants",
        icon = "carrot",
        name = "植物",
        prefabs = g_util.ground_plants,
    },
    {
        id = "container",
        icon = "treasurechest",
        name = "容器",
        prefabs = g_util.ground_container,
    },
}



return {
    default = "craftingstation",
    cates = cates,
}