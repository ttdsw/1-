local g_util = require "util/fn_gallery"


local data = {
    default = "ingredients",
    cates = {{
        id = "all",
        icon = "filter_none",
        name = STRINGS.UI.COOKBOOK.FILTER_ALL,
        prefabs = g_util.food_all,
        
    },{
        id = "ingredients",
        icon = "quagmire_turnip",
        name = "食材(可入锅)",
        prefabs = g_util.food_ingredients,
    },{
        id = "recipe",
        icon = "cookpot",
        name = "料理(普通锅)",
        prefabs = g_util.food_recipe,
    },{
        id = "recipe_else",
        icon = "portablecookpot_item",
        name = "料理(特殊锅)",
        prefabs = g_util.food_recipe_else,
    },{
        id = "recipe_spice",
        icon = "portablespicer_item",
        name = "料理(调味)",
        prefabs = g_util.food_recipe_spice,
    },{
        id = "ingredients_veggie",
        icon = "carrot",
        name = "食材(素)",
        prefabs = g_util.food_ingredients_veggie,
    },{
        id = "ingredients_meat",
        icon = "meat",
        name = "食材(荤)",
        prefabs = g_util.food_ingredients_meat,
    },{
        id = "ingredients_else",
        icon = "twigs",
        name = "食材(非荤非素)",
        prefabs = g_util.food_ingredients_else,
    },{
        id = "feast",
        icon = "berrysauce",
        name = "节日专属"..g_util.str_seemore,
        prefabs = g_util.food_feast,
        fn_rr = g_util.SeeMore("节日专属", "冬季盛宴和万圣节的相关食物，\n萌新注意：有些料理只能在餐桌上面享用")
    },{
        id = "caneat",
        icon = "glommerfuel",
        name = "特殊食物"..g_util.str_seemore,
        prefabs = g_util.food_caneat,
        fn_rr = g_util.SeeMore("特殊食物", "这里的食物不包括模组食物和节日料理,\n可以食用, 但不能入锅")
    },}, 
}

return data