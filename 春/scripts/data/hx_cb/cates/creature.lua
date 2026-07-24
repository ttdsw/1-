local g_util = require "util/fn_gallery"


local data = {
    default = "common",
    cates = {{
        id = "all",
        icon = "filter_none",
        name = STRINGS.UI.COOKBOOK.FILTER_ALL..g_util.str_seemore,
        prefabs = g_util.creature_all,
        
        fn_rr = g_util.SeeMore("模组支持", '整个标签下的分类是根据图鉴数据自动整理的，\n模组作者如需在此显示请通过此文件追加:\nrequire("screens/redux/scrapbookdata")')
    }, {
        id = "common",
        icon = "filter_pigman",
        name = STRINGS.UI.RARITY.Common..g_util.str_seemore,
        prefabs = g_util.creature_common,
        fn_rr = g_util.SeeMore("生物", "相比旧版T键，能放在物品栏的生物已经不在此分类中，\n鱼类等小兽请看右边【小兽】分类")
    }, {
        id = "giants",
        icon = "filter_giants",
        name = STRINGS.SCRAPBOOK.CATS.GIANTS,
        prefabs = g_util.creature_giants,
    }, {
        id = "inv",
        icon = "robin",
        name = "小兽"..g_util.str_seemore,
        prefabs = g_util.creature_inv,
        fn_rr = g_util.SeeMore("小兽", "能放在物品栏的生物都在此分类中，甚至包括啜食者。")
    }, {
        id = "player",
        icon = "filter_player",
        name = "冒险家",
        prefabs = g_util.creature_player,
    },{
        id = "pet",
        icon = "critterlab",
        name = "宠物"..g_util.str_seemore,
        prefabs = g_util.creature_pet,
        fn_rr = g_util.SeeMore("宠物", "之后的版本在刷出宠物时，会自动跟随，暂时不支持此功能。")
    },{
        id = "shadow",
        icon = "shadowrift_portal",
        name = STRINGS.SCRAPBOOK.NOTE_SHADOW_ALIGNED..g_util.str_seemore,
        prefabs = g_util.creature_shadow,
        fn_rr = g_util.SeeMore(STRINGS.SCRAPBOOK.NOTE_SHADOW_ALIGNED, "根据图鉴数据进行的分类，所以也会包括拳击袋等非生物。\n(此分类不计入左侧【全部】分类，授权后可查看更多生物)"),
        hot = true,
    },{
        id = "lunar",
        icon = "lunarrift_portal",
        name = STRINGS.SCRAPBOOK.NOTE_LUNAR_ALIGNED..g_util.str_seemore,
        prefabs = g_util.creature_lunar,
        fn_rr = g_util.SeeMore(STRINGS.SCRAPBOOK.NOTE_LUNAR_ALIGNED, "根据图鉴数据进行的分类，所以也会包括拳击袋等非生物。\n(此分类不计入左侧【全部】分类，授权后可查看更多生物)"),
        hot = true,
    },{
        id = "normal",
        icon = "beefalo",
        name = "普通无阵营"..g_util.str_seemore,
        prefabs = g_util.creature_normal,
        fn_rr = g_util.SeeMore("普通无阵营", "对【普通】再过滤，展示更常见的生物。\n此分类也许会展示部分阵营生物，需要授权才能过滤掉。"),
        hot = true,
    }}
}


return data