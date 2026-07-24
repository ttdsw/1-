local g_util = require "util/fn_gallery"
local m_util = require "util/modutil"
local h_util = require "util/hudutil"
local save_data = require("util/fn_hxcb").save_data
local i_util = require "util/inpututil"
local t_util = require "util/tableutil"

local cates = t_util:IPairFilter(i_util:GetModsToLoad(), function(modname)
    local mod = ModManager:GetMod(modname) or {}
    local prefabs = mod.Prefabs or {}
    local modinfo = mod.modinfo or {}
    if save_data.modfilter and modinfo.client_only_mod then
        return
    end
    if t_util:GetSize(prefabs) > 0 then
        local asset = h_util:GetModAsset(modname)
        return {
            id = modname,
            name = asset.name,
            icon = function()
                if asset.xml and TheSim:AtlasContains(asset.xml, asset.tex) then
                    return asset.xml, asset.tex
                else
                    return h_util:GetPrefabAsset("filter_modded")
                end
            end,
            prefabs = function()
                return t_util:PairToIPair(prefabs, function(prefab, info)
                    return type(info)=="table" and not info.rarity and not prefab:find("_buff") and not prefab:find("_placer") and not prefab:find("_fx") and prefab
                end)
            end
        }
    end
end)
table.insert(cates, 1, {
    id = "all",
    icon = "filter_none",
    name = STRINGS.UI.COOKBOOK.FILTER_ALL..g_util.str_seemore,
    prefabs = g_util.mod_all,
    fn_rr = g_util.SeeMore("关于模组", "模组通过Prefabs注册后就会显示在这里, 右侧可筛选查看。\n客户端模组注册的实体，右侧分类会被设置中的【模组过滤】选项过滤掉, \n但始终会在【全部】中显示。")
})


return {
    default = "all",
    cates = cates,
}