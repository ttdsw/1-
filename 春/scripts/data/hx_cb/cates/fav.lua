local g_util = require "util/fn_gallery"
local t_util = require "util/tableutil"
local f_util = require "util/fn_hxcb"


local cates = t_util:IPairToIPair({"craft", "creature", "food", "equip", "items", "ground", "mod"}, function(id)
    return {
        id = id,
        icon = f_util:GetTagIcon(id) or "filter_none",
        name = f_util:GetTagName(id) or id,
        prefabs = g_util.fav_tag(id),
        hot = true,
    }
end)



table.insert(cates, 1, {
    id = "all",
    icon = "filter_favorites",
    name = STRINGS.UI.COOKBOOK.FILTER_ALL..g_util.str_seemore,
    prefabs = g_util.fav_all,
    fn_rr = g_util.SeeMore("功能联动", "使用【绘卷·夏】的快捷宣告后，被宣告的物品就会显示在这里，并排第一位。"),
    nosort = true,
    hot = true,
})

return {
    default = "all",
    cates = cates,
}