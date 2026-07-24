local g_util = require "util/fn_gallery"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local Cates = {}

t_util:IPairs(CRAFTING_FILTER_DEFS or {}, function(data)
    local cname = data.name
    local hover = type(cname)=="string" and t_util:GetRecur(STRINGS, "UI.CRAFTING_FILTERS."..cname)
    if not hover then return end
    table.insert(Cates, {
        id = cname,
        name = hover,
        icon = function()
            if cname == "CHARACTER" then
                return h_util:GetPrefabAsset("filter_player")
            elseif cname == "CRAFTING_STATION" then
                return h_util:GetPrefabAsset("station_none")
            end
            local xml = (ThePlayer and type(data.atlas)=="function" and data.atlas(ThePlayer)) or (type(data.atlas)=="string" and data.atlas) or resolvefilepath(CRAFTING_ICONS_ATLAS)
            local tex = (ThePlayer and type(data.image)=="function" and data.image(ThePlayer)) or (type(data.image)=="string" and data.image)
            return xml, tex
        end,
        prefabs = g_util.craft_get(cname),
    })
end)





local Cates_0, Cates_1, Cates_2 = {
    {
        id = "role",
        name = "角色专属"..g_util.str_seemore,
        icon = function()
            
            
            return h_util:GetPrefabAsset(ThePlayer and ThePlayer.prefab)
        end,
        prefabs = g_util.craft_role,
        fn_rr = g_util.SeeMore("关于角色专属", "这个分类下显示的物品是实时生成的，\n比如威尔逊不点炼金术的话，此处就不会显示配方。\n角色有了对应技能树或者标签，刷新后就能显示对应分类物品了。"),
        hot = true,
    }
}, {}, {}
t_util:IPairs(Cates, function(data)
    if data.id == "FAVORITES" then
    elseif data.id == "EVERYTHING" then
        data.prefabs = g_util.craft_all
        data.id = "all"
        table.insert(Cates_0, 1, data)
    elseif table.contains({"CHARACTER", "CRAFTING_STATION", "SPECIAL_EVENT", "MODS"}, data.id) then
        table.insert(Cates_2, 1, data)
    else
        table.insert(Cates_1, data)
    end
end)



return {
    default = "role",
    cates = t_util:MergeList(Cates_0, Cates_1, Cates_2),
}