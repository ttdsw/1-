
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local data = {
    default = "normal",
    cates = {{
        id = "all",
        icon = "filter_none",
        name = STRINGS.UI.COOKBOOK.FILTER_ALL,
        filter = function(data) return true end
    },{
        id = "normal",
        icon = "filter_cosmetic",
        name = "常用",
        filter = function(data) return data.inv or data.code:find("OCEAN_") or table.contains({"DIRT", "IMPASSABLE", "FARMING_SOIL", "VAULT", "RIFT_MOON"}, data.code) end
    },{
        id = "inv",
        icon = "station_turfcrafting",
        name = "有地皮",
        filter = function(data) return data.inv end
    },{
        id = "sea",
        icon = "station_hermitcrab_shop",
        name = "海洋",
        filter = function(data) return data.code:find("OCEAN_") or table.contains({"MONKEY_DOCK"}, data.code) end
    },{
        id = "quag",
        icon = "recipe_unknown",
        name = "暴食",
        filter = function(data) return data.code:find("QUAGMIRE_") end
    },{
        id = "lava",
        icon = "lavaarena_crowndamagerhat",
        name = "熔炉\n该地块儿分类不推荐！可能崩溃！",
        filter = function(data) return data.code:find("LAVAARENA_") end
    },{
        id = "noise",
        icon = "station_cartography",
        name = "纹理",
        filter = function(data) return data.code:find("_NOISE") end
    },}, 
}

local data_mods = {}
local minimaps = require ("worldtiledefs").minimap
t_util:IPairs(minimaps or {}, function(set)
    local tile_id, minimap_tile_def = set[1], set[2]
    if minimap_tile_def then
        local noise_texture = minimap_tile_def.noise_texture
        local modpath = type(noise_texture) == "string" and string.match(noise_texture, "mods/([^/]+)")
        if modpath then
            if not data_mods[modpath] then
                data_mods[modpath] = {}
            end
            table.insert(data_mods[modpath], tile_id)
        end
    end
end)

t_util:Pairs(data_mods, function(modpath, tile_ids)
    local asset = h_util:GetModAsset(modpath)
    table.insert(data.cates, {
        id = modpath,
        name = asset.name,
        icon = function()
            if asset.xml and TheSim:AtlasContains(asset.xml, asset.tex) then
                return asset.xml, asset.tex
            else
                return h_util:GetPrefabAsset("filter_modded")
            end
        end,
        filter = function(data) return table.contains(tile_ids, data.id) end
    })
end)

table.insert(data.cates, {
    id = "isold",
    icon = "pitchfork",
    name = "非官方接口",
    filter = function(data) return data.isold end
})

return data