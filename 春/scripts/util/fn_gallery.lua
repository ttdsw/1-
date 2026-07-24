local SB = require("screens/redux/scrapbookdata")
local SS = require("data/redirectdata").prefab_scrap
local COOKING = require "cooking"
local s_mana = require "util/settingmanager"
local c_util = require "util/calcutil"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local f_util = require "util/fn_hxcb"
local e_util = require "util/entutil"
local save_data = f_util.save_data
local m_util = require "util/modutil"
local i_util = require "util/inpututil"
local r_data = require "data/redirectdata"
local GroundTiles = require("worldtiledefs")

local g_util = {
    str_seemore = "\n"..STRINGS.RMB.."查看详情",
    prefabs = {}
}


local list_creature_giants_add = {"leif_sparse", "deciduousmonster", 
"warglet", "warg", "claywarg", "gingerbreadwarg", 
"spat", 
"alterguardian_phase1", "alterguardian_phase2", "alterguardian_phase3", 
"shadowthrall_hands", "shadowthrall_horns", "shadowthrall_wings", 
"rabbitking_passive", "rabbitking_aggressive", "rabbitking_lucky", 
"lunarthrall_plant", 
"shadowthrall_centipede_controller",
}
local list_creature_common_add = {
    "bigshadowtentacle", "canary_poisoned", "carrat_ghostracer", "clayhound",
    "crawlingnightmare", "fireflies", "hedgehound_bush", "hermitcrab", "houndcorpse",
    "lunarthrall_plant", "moonhound", "moonpig", "nightmarebeak", "pondeel",
    "pondfish", "pigelite1", "pigelite2", "pigelite3", "pigelite4", "ruins_shadeling",
    "shadowheart_infused", "spore_moon", "stalker_minion1", "stalker_minion2",
    "ticoon", "trap_starfish","gestalt", "lunarthrall_plant_gestalt",
    "wobysmall", 
    "knight_yoth",
}

local list_creature_common_sub = {
    
    "stalker_minion", 
    "shadowthrall_centipede_head", 
}

local list_creature_inv_sub = {"bat", "beefalo", "ticoon"}

local list_creature_pet_add = {"smallghost","abigail", 
"lavae_pet", "chester", "glommer", 
"bernie_active", "bernie_big", 
"ticoon", 
"wobybig","wobysmall"
}

local list_creature_player_add = {"charlie_npc", "wagstaff_npc", "wanderingtrader"}

local tags_shadow = {"shadow", "shadowminion", "shadowchesspiece", "stalker", "stalkerminion", "shadowthrall", "shadow_aligned"}

local list_items_plant_add = {"acorn", "tree_rock_seed", "ancienttree_gem_sapling_item", "ancienttree_nightvision_sapling_item", "ancienttree_seed", "lureplantbulb"}



function g_util.creature_giants()
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
        return line.type == "giant" and prefab
    end)
    t_util:AddIPairs(list_creature_giants_add, prefabs)
    return prefabs
end

function g_util.creature_default()
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
        return line.type == "creature" and prefab
    end)
    t_util:SubIPairs(list_creature_giants_add, prefabs)
    t_util:SubIPairs(list_creature_common_sub, prefabs)
    t_util:AddIPairs(list_creature_common_add, prefabs)

    return prefabs
end


function g_util.creature_common()
    local prefabs = t_util:IPairFilter(g_util.creature_default(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return xml and not xml:find("inventoryimages") and prefab
    end)
    
    return t_util:AddIPairs(list_creature_inv_sub, prefabs)
end



function g_util.creature_inv()
    local prefabs = t_util:IPairFilter(g_util.creature_default(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return h_util:IsInvXml(xml) and prefab
    end)
    t_util:SubIPairs(list_creature_inv_sub, prefabs)
    return prefabs
end

function g_util.creature_pet()
    local prefabs = t_util:PairToIPair(Prefabs, function(prefab)
        return type(prefab)=="string" and prefab:sub(1, 8) == "critter_" and not prefab:find("_builder") and prefab
    end)
    t_util:AddIPairs(list_creature_pet_add, prefabs)
    return prefabs
end

function g_util.creature_player()
    return t_util:AddIPairs(list_creature_player_add, t_util:MergeList(MODCHARACTERLIST, DST_CHARACTERLIST))
end

function g_util.creature_all()
    if not g_util.prefabs.creature then
        g_util.prefabs.creature = t_util:AddIPairs(t_util:MergeList(g_util.creature_common(), g_util.creature_giants(), g_util.creature_inv(), g_util.creature_player(), g_util.creature_pet()))
    end
    return g_util.prefabs.creature
end

function g_util.creature_shadow()
    if not g_util.prefabs.creature_shadow then
        local prefabs = t_util:PairToIPair(SB, function(prefab, line)
            return line.notes and line.notes.shadow_aligned and prefab
        end)
        if save_data.__authorize then
            t_util:AddIPairs(t_util:IPairFilter(g_util.creature_all(), function(prefab)
                return t_util:IGetElement(e_util:ClonePrefab(prefab).tags, function(tag)
                    return table.contains(tags_shadow, tag)
                end) and prefab
            end), prefabs)
        end
        t_util:SubIPairs(list_creature_common_sub, prefabs)
        g_util.prefabs.creature_shadow = prefabs
    end
    return g_util.prefabs.creature_shadow
end

function g_util.creature_lunar()
    if not g_util.prefabs.creature_lunar then
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
           return line.notes and line.notes.lunar_aligned and prefab
    end)
    if save_data.__authorize then
        t_util:IPairs(g_util.creature_all(), function(prefab)
            if table.contains(e_util:ClonePrefab(prefab).tags, "lunar_aligned") then
                t_util:Add(prefabs, prefab)
            end
        end)
    end
    
    g_util.prefabs.creature_lunar = prefabs
    end
    return g_util.prefabs.creature_lunar
end

function g_util.creature_normal()
    if not g_util.prefabs.creature_normal then
        g_util.prefabs.creature_normal = t_util:SubIPairs(t_util:MergeList(g_util.creature_shadow(), g_util.creature_lunar()), g_util.creature_common())
    end
    return g_util.prefabs.creature_normal
end



function g_util.food_ingredients()
    local prefabs = t_util:PairToIPair(COOKING.ingredients or {}, function(prefab)
        return Prefabs[prefab] and prefab
    end)
    local aliases = c_util:GetFnValue(COOKING.IsCookingIngredient, "aliases") or {}
    t_util:Pairs(aliases, function(aliase, name)
        t_util:Add(prefabs, aliase)
    end)

    return prefabs
end
function g_util.food_ingredients_veggie()
    local prefabs = t_util:IPairFilter(g_util.food_ingredients(), function(prefab)
        local tags = t_util:GetRecur(COOKING, "ingredients."..prefab..".tags") or {}
        return (tags.veggie or tags.fruit) and prefab
    end)
    
    t_util:AddIPairs(t_util:IPairFilter(g_util.food_ingredients(), function(prefab)
        return t_util:GetRecur(SB, prefab..".foodtype")=="VEGGIE" and prefab
    end), prefabs)
    return prefabs
end
function g_util.food_ingredients_meat()
    
    local prefabs = t_util:IPairFilter(g_util.food_ingredients(), function(prefab)
        local tags = t_util:GetRecur(COOKING, "ingredients."..prefab..".tags") or {}
        return (tags.meat or tags.egg) and prefab
    end)
    
    t_util:AddIPairs(t_util:IPairFilter(g_util.food_ingredients(), function(prefab)
        return t_util:GetRecur(SB, prefab..".foodtype")=="MEAT" and prefab
    end), prefabs)
    return prefabs
end
function g_util.food_ingredients_else()
    local veggies = g_util.food_ingredients_veggie()
    local meats = g_util.food_ingredients_meat()
    return t_util:IPairFilter(g_util.food_ingredients(), function(prefab)
        return not table.contains(veggies, prefab) and not table.contains(meats, prefab) and prefab
    end)
end

function g_util.food_recipe()
    return t_util:PairToIPair(t_util:GetRecur(COOKING, "recipes.cookpot") or {}, function(prefab)
        return Prefabs[prefab] and prefab
    end)
end

function g_util.food_recipe_spice()
    return t_util:PairToIPair(t_util:GetRecur(COOKING, "recipes.portablespicer") or {}, function(prefab)
        return Prefabs[prefab] and prefab
    end)
end

function g_util.food_recipe_else()
    local foods = t_util:MergeList(g_util.food_recipe(), g_util.food_recipe_spice())
    local prefabs = {}
    t_util:Pairs(COOKING.recipes or {}, function(potname, fooddata)
        if not table.contains({"cookpot", "portablespicer"}, potname) then
            t_util:Pairs(fooddata, function(food, data)
                if not table.contains(foods, food) and Prefabs[food] then
                    t_util:Add(prefabs, food)
                end
            end)
        end
    end)
    return prefabs
end

function g_util.food_caneat()
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
        return line.type == "food" and prefab
    end)
    t_util:SubIPairs(g_util.food_recipe_all(), prefabs)
    t_util:SubIPairs(g_util.food_ingredients(), prefabs)
    t_util:SubIPairs(g_util.food_feast(), prefabs)
    return prefabs
end

function g_util.food_recipe_all()
    local recipes = {}
    t_util:Pairs(COOKING.recipes or {}, function(potname, fooddata)
        t_util:Pairs(fooddata, function(food, data)
            if Prefabs[food] then
                t_util:Add(recipes, food)
            end
        end)
    end)
    return recipes
end

function g_util.food_feast()
    return t_util:PairToIPair(SB, function(prefab, line)
        if line.subcat == "wintersfeastfood" then
            return prefab
        elseif line.type == "food" and table.contains({"halloweencandy", "halloween_potions", "winter_ornaments", "cookie_crumbs", "wintersfeastfuel"}, line.build) then
            return prefab
        end
    end)
end


function g_util.food_all()
    if not g_util.prefabs.food then
        local prefabs = t_util:PairToIPair(SB, function(prefab, line)
            return line.type == "food" and prefab
        end)
        t_util:AddIPairs(g_util.food_recipe_all(), prefabs)
        t_util:AddIPairs(g_util.food_ingredients(), prefabs)
        t_util:AddIPairs(g_util.food_feast(), prefabs)
        g_util.prefabs.food = prefabs
    end
    return g_util.prefabs.food
end


function g_util.craft_get(name)
    return function()
        local prefabs = {}
        if name then
            local listcraft = t_util:GetRecur(CRAFTING_FILTERS, name..".recipes")
            t_util:Pairs(type(listcraft)=="table" and listcraft or {}, function(_, prefab)
                if type(prefab) == "string" then
                    local recipe = AllRecipes[prefab] or {}
                    local product = type(recipe.product) == "string" and recipe.product
                    t_util:Add(prefabs, product or prefab)
                    
                end
            end)
        end
        return g_util.FilterBuilder(prefabs)
    end
end
function g_util.craft_role()
    local prefabs = {}
    if not ThePlayer then
        return prefabs
    end
    local listcraft = t_util:GetRecur(CRAFTING_FILTERS, "CHARACTER.recipes")
    t_util:Pairs(type(listcraft)=="table" and listcraft or {}, function(_, prefab)
        if type(prefab) == "string" then
            local recipe = AllRecipes[prefab] or {}
            local product = type(recipe.product) == "string" and recipe.product
            local flag
            
            if recipe.builder_tag then
                flag = ThePlayer:HasTag(recipe.builder_tag)
            elseif recipe.builder_skill then
                local p_util = require "util/playerutil"
                flag = p_util:IsSkillTreeActivated(recipe.builder_skill)
            else
                
                flag = AllRecipes[prefab]
            end
            if flag then
                t_util:Add(prefabs, product or prefab)
            end
        end
    end)
    return g_util.FilterBuilder(prefabs)
end
function g_util.craft_all()
    if not g_util.prefabs.craft then
        local prefabs = t_util:PairToIPair(AllRecipes, function(prefab, recipe)
            if type(prefab) == "string" then
                local product = type(recipe.product) == "string" and recipe.product
                return product or prefab
            end
        end)
        g_util.prefabs.craft = g_util.FilterBuilder(prefabs)
    end
    return g_util.prefabs.craft
end




local specialinfos_plant = {"PLANTABLE_FERTILIZE", "PLANTABLE", "NEEDFERTILIZER"}
local subcats_plant = {"farmplant", "tree"}
function g_util.all_plants()
    return t_util:PairToIPair(SB, function(prefab, line)
        return (table.contains(specialinfos_plant, line.specialinfo) 
            or table.contains(subcats_plant, line.subcat)
        )and prefab
    end)
end


function g_util.all_walls()
    return g_util.Subcat("wall")
end










function g_util.items_material()
    local items, num_target = {}, 0
    t_util:Pairs(AllRecipes, function(_, recipe)
        t_util:Pairs(type(recipe)=="table" and recipe.ingredients or {}, function(__, ing)
            if type(ing.type) == "string" then
                local amount = type(ing.amount)=="number" and ing.amount or 1
                
                if items[ing.type] then
                    items[ing.type] = items[ing.type] + amount
                else
                    items[ing.type] = amount
                end
            end
        end)
    end)
    local items_list = t_util:PairToIPair(items, function(prefab, amount)
        return {prefab, amount}
    end)
    table.sort(items_list, function(a, b)
        return a[2] > b[2]
    end)
    
    
    
    

    
    return t_util:IPairFilter(items_list, function(data)
        return data[2] > num_target and data[1]
    end)
end


local tags_ornament = {"ornament", "halloweenornament"}
function g_util.items_ornament()
    return t_util:PairToIPair(SB, function(prefab, line)
        return (table.contains(tags_ornament, line.subcat) or line.specialinfo == "WINTERTREE_ORNAMENT") and prefab
    end)
end

local tags_trinket = {"trinket", "wagstafftool", "hauntedtoy", "shell"}
function g_util.items_trinket()
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
        return table.contains(tags_trinket, line.subcat) and prefab
    end)

    return t_util:AddIPairs({"trinket_8", "trinket_17"}, prefabs)
end

function g_util.items_plant()
    local prefabs = t_util:IPairFilter(g_util.all_plants(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return h_util:IsInvXml(xml) and prefab
    end)
    
    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS or {}
    local seeds = t_util:PairToIPair(PLANT_DEFS, function(prefab, line)
        return type(line.seed) == "string" and line.seed
    end)

    
    t_util:AddIPairs(list_items_plant_add, prefabs)
    return t_util:AddIPairs(seeds, prefabs)
end

function g_util.items_garden()
    local prefabs = g_util.craft_get("GARDENING")()
    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS or {}
    t_util:Pairs(PLANT_DEFS, function(_, line)
        if type(line.seed) == "string" then
            table.insert(prefabs, line.seed)
        end
        
        
        
        if type(line.product) == "string" then
            table.insert(prefabs, line.product)
        end
        
        
        
    end)
    return t_util:AddIPairs({"red_cap", "green_cap", "blue_cap", "moon_cap"}, prefabs)
end

function g_util.items_wall()
    return t_util:IPairFilter(g_util.all_walls(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return h_util:IsInvXml(xml) and prefab
    end)
end


function g_util.items_seafaring()
    return t_util:PairToIPair(SB, function(prefab, line)
        return (table.contains({"seafaring"}, line.subcat) 
        or table.contains({"PADDLE"}, line.specialinfo)
    )and prefab
    end)
end
function g_util.items_fishing()
    return t_util:PairToIPair(SB, function(prefab, line)
        return table.contains({"oceanfish", "tackle"}, line.subcat) and prefab
    end)
end


function g_util.items_prop()
    local tags = t_util:MergeList({"wintersfeastfood"})
    local prefabs = t_util:PairToIPair(SB, function(prefab, line)
        if line.type == "item" 
        and not table.contains(tags, line.subcat) 
        and not table.contains({"idle_oversized"}, line.anim)
        then
            local xml = h_util:GetPrefabAsset(prefab)
            return h_util:IsInvXml(xml) and not AllRecipes[prefab] and prefab
        end
    end)
    t_util:SubIPairs(g_util.items_ornament(), prefabs)
    t_util:SubIPairs(g_util.items_trinket(), prefabs)
    t_util:SubIPairs(g_util.items_material(), prefabs)
    t_util:SubIPairs(g_util.items_plant(), prefabs)
    t_util:SubIPairs(g_util.equip_all(), prefabs)
    t_util:SubIPairs(g_util.food_all(), prefabs)

    return prefabs
end

function g_util.items_turf()
    return g_util.Subcat("turf")
end

function g_util.items_all()
    if not g_util.prefabs.items then
        g_util.prefabs.items = t_util:PairToIPair(SB, function(prefab, line)
            return line.type == "item" and prefab
        end)
        t_util:SubIPairs(g_util.equip_all(), g_util.prefabs.items)
    end
    return g_util.prefabs.items
end

function g_util.ground_plants()
    return t_util:IPairFilter(g_util.all_plants(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return xml and not xml:find("inventoryimages") and prefab
    end)
end

function g_util.ground_structure()
    return g_util.Subcat("structure")
end

function g_util.ground_wall()
    return t_util:IPairFilter(g_util.all_walls(), function(prefab)
        local xml = h_util:GetPrefabAsset(prefab)
        return not h_util:IsInvXml(xml) and prefab
    end)
end

function g_util.ground_lab()
    return g_util.Subcat("craftingstation")
end

function g_util.ground_atrium()
    return g_util.Subcat("atrium")
end

function g_util.ground_container()
    return g_util.Subcat("container")
end

function g_util.ground_all()
    if not g_util.prefabs.ground then
        g_util.prefabs.ground = t_util:MergeList(
            g_util.ground_plants(),
            g_util.ground_structure(),
            g_util.ground_wall(),
            g_util.ground_lab(),
            g_util.ground_atrium(),
            g_util.ground_container()
        )
        t_util:AddIPairs(t_util:PairToIPair(SB, function(prefab, line)
            return line.type == "thing" and prefab
        end), g_util.prefabs.ground)
    end
    return g_util.prefabs.ground
end


local save_id, save_equips = "GALLERY_", {}
local eslots = {"head", "hands", "body", "sculp"}
t_util:IPairs(eslots, function(eslot)
    save_equips[eslot] = s_mana:GetSettingLine(save_id..eslot, true)
end)


function g_util.equip_eslot(eslot)
    return function()
        return t_util:AddIPairs(g_util.equip_ori_list(eslot), t_util:PairToIPair(g_util.equip_file_map(eslot), function(prefab)
            return Prefabs[prefab] and prefab
        end))
    end
end

function g_util.equip_ori_list(eslot)
    local status, info = pcall(require, "data/hx_cb/equip/"..eslot)
    if status and type(info)=="table" then
        return info
    else
        return {}
    end
end

function g_util.equip_file_map(eslot)
    return save_data.equipmem and save_equips[eslot] or {}
end

local equips_data = {}

function g_util.equip_mapget(eslot)
    if not equips_data[eslot] then
        equips_data[eslot] = {}
        t_util:IPairs(g_util.equip_ori_list(eslot), function(prefab)
            equips_data[eslot][prefab] = true
        end)
        t_util:Pairs(g_util.equip_file_map(eslot), function(prefab)
            equips_data[eslot][prefab] = true
        end)
    end
    return equips_data[eslot]
end

function g_util.equip_save(slot, equip)
    if not save_data.equipmem then return end
    local eslot, prefab = "body", equip.prefab
    if table.contains({"hands", "head"}, slot) then
        eslot = slot
    elseif equip:HasTag("heavy") then
        eslot = "sculp"
    end
    local equips = g_util.equip_mapget(eslot)
    if not equips[prefab] then
        
        equips[prefab] = true
        
        save_equips[eslot][prefab] = true
        s_mana:SaveSettingLine(save_id..eslot, save_equips[eslot])
        
    end
end

function g_util.equip_memory()
    local prefabs = {}
    t_util:IPairs(eslots, function(eslot)
        t_util:Pairs(g_util.equip_file_map(eslot), function(prefab)
            t_util:Add(prefabs, prefab)
        end)
    end)
    return prefabs
end

function g_util.equip_clear()
    h_util:CreatePopupWithClose("提示", "您确定要清理这些记忆的装备吗？\n它们将不再出现在左边的分类中！",{
        {text = "确定清理", cb = function()
            t_util:IPairs(eslots, function(eslot)
                save_equips[eslot] = {}
                s_mana:SaveSettingLine(save_id..eslot, {})
                local ui = h_util:GetCB()
                if ui then
                    ui:BuildUI()
                end
            end)
            t_util:Clear(equips_data)
        end},
        {text = h_util.no},
    })
end

function g_util.equip_all()
    local prefabs = t_util:MergeList(
        g_util.equip_eslot("hands")(), 
        g_util.equip_eslot("head")(),
        g_util.equip_eslot("body")(),
        g_util.equip_eslot("sculp")(),
        g_util.equip_sew()
    )

    return t_util:IPairFilter(prefabs, function(prefab)
        return Prefabs[prefab] and prefab
    end)
end

function g_util.equip_costume()
    return g_util.Subcat("costume")
end

function g_util.equip_armor()
    return g_util.Subcat("armor")
end

function g_util.equip_backpack()
    return g_util.Subcat("backpack")
end

function g_util.equip_clothing()
    return g_util.Subcat("clothing")
end

function g_util.equip_hat()
    return g_util.Subcat("hat")
end

function g_util.equip_weapon()
    return g_util.Subcat("weapon")
end

function g_util.equip_tool()
    return g_util.Subcat("tool")
end

function g_util.equip_sew()
    local prefabs = g_util.equip_eslot("sew")()
    local sd = s_mana:GetSettingLine("sw_hjsl_repair", true) or {}
    t_util:Pairs(sd.list or {}, function(_, data)
        t_util:IPairs(type(data.ing) == "table" and data.ing or {}, function(prefab)
            if Prefabs[prefab] then
                t_util:Add(prefabs, prefab)
            end
        end)
    end)
    return prefabs
end

function g_util.mod_all()
    if not g_util.prefabs.mod then
        g_util.prefabs.mod = {}
        t_util:IPairs(i_util:GetModsToLoad(), function(modname)
            t_util:PairToIPair(t_util:GetRecur(ModManager:GetMod(modname), "Prefabs") or {}, function(prefab, info)
                if type(info)=="table" and not info.rarity and not prefab:find("_buff") and not prefab:find("_placer") and not prefab:find("_fx") then
                    table.insert(g_util.prefabs.mod, prefab)
                end
            end)
        end)
    end
    return g_util.prefabs.mod
end






function g_util.all_all()
    if not g_util.prefabs.all then
        g_util.prefabs.all = t_util:PairToIPair(Prefabs or {}, function(prefab, info)
            return not info.rarity and not prefab:find("_buff") and not prefab:find("_placer") and not prefab:find("_fx") and not prefab:find("MOD_") and prefab
        end)
    end
    return g_util.prefabs.all
end
function g_util.color_all()
    if not g_util.prefabs.color then
        g_util.prefabs.color = t_util:IPairFilter(g_util.all_all(), function(prefab)
            return not h_util:GetPrefabAsset(prefab) and prefab
        end)
        table.sort(g_util.prefabs.color, function(a, b)
            local ga = e_util:GetPrefabName(a) ~= e_util.NullName
            local gb = e_util:GetPrefabName(b) ~= e_util.NullName
            if ga and not gb then
                return true
            elseif gb and not ga then
                return false
            else
                return a < b
            end
        end)
    end
    return g_util.prefabs.color
end

function g_util.poi_all()
    return f_util:GetSavePoi()
end



function g_util.fav_all()
    local prefabs = {}
    t_util:Pairs(save_data.favs or {}, function(tag, ps)
        t_util:AddIPairs(ps, prefabs)
    end)
    table.sort(prefabs, g_util.SortSB)
    local prefab = t_util:GetPrefab()
    if prefab then
        t_util:Sub(prefabs, prefab)
        table.insert(prefabs, 1, prefab)
    end
    return prefabs
end

function g_util.fav_tag(tag)
    return function()
        return t_util:GetRecur(save_data, "favs."..tag) or {}
    end
end



local UnitData = {}
local food_recipe_all, food_recipe_spice
function g_util:UnitsGet(prefab)
    local list = UnitData[prefab]
    
    if not list and prefab then
        list = {}
        
        food_recipe_all = food_recipe_all or self.food_recipe_all()
        if table.contains(food_recipe_all, prefab) then
            
            local baseprefab, spice_start = prefab, prefab:find("_spice_")
            if spice_start then
                baseprefab = prefab:sub(1, spice_start - 1)
            end
            t_util:Add(list, baseprefab)
            food_recipe_spice = food_recipe_spice or self.food_recipe_spice()
            
            
            if baseprefab == prefab then
                t_util:IPairs(food_recipe_spice, function(prefab_spice)
                    if prefab_spice:rfind_plain(baseprefab) then
                        t_util:Add(list, prefab_spice)
                    end
                end)
            end
            
            local cb_data = t_util:GetRecur(TheCookbook, "preparedfoods."..baseprefab..".recipes")
            t_util:IPairs(type(cb_data)=="table" and cb_data or {}, function(data)
                t_util:Pairs(type(data) == "table" and data or {}, function(_, ing)
                    if type(ing) == "string" and Prefabs[ing] then
                        t_util:Add(list, ing)
                    end
                end)
            end)
        elseif table.contains(self.creature_player(), prefab) then
            
            local start_items = t_util:GetRecur(TUNING, "GAMEMODE_STARTING_ITEMS.DEFAULT."..prefab:upper())
            t_util:AddIPairs(start_items or {}, list)
        else
            
            local ings = t_util:GetRecur(AllRecipes, prefab..".ingredients")
            local ret = t_util:PairToIPair(ings or {}, function(_, info)
                if type(info) == "table" then
                    if type(info.type) == "string" and Prefabs[info.type] then
                        t_util:Add(list, info.type)
                    end
                end
            end)
            
            t_util:AddIPairs(self:GetScrapBookDeps(prefab), list)
            
            t_util:AddIPairs(self:UnitsHuxi(prefab), list)
        end
        
        t_util:Sub(list, prefab)
        UnitData[prefab] = list
    end
    
    return list
end

function g_util:UnitsHuxi(prefab)
    if not m_util:IsHuxi() then return {} end
    local units = require "data/hx_cb/units"
    return units[prefab] or {}
end


function g_util:GetScrapBookDeps(prefab)
    local sc_data = SB[prefab] and SB[prefab].deps or {}
    
    local ss_data = SS[prefab]
    if ss_data then
        if ss_data.sketch then
            t_util:Add(sc_data, ss_data.sketch.."_sketch")
            t_util:Sub(sc_data, "sketch")
        end
        if ss_data.add then
            t_util:Add(sc_data, ss_data.add)
        end
        if ss_data.prefab then
            sc_data = SB[ss_data.prefab] and SB[ss_data.prefab].deps or sc_data
        end
    end
    local ret = {}
    t_util:IPairs(sc_data, function(prefab_sc)
        
        if prefab_sc == "sketch" then
            local prefab_re = "chesspiece_"..prefab.."_sketch"
            t_util:Add(ret, Prefabs[prefab_re] and prefab_re or prefab_sc)
        elseif prefab_sc == "blueprint" then
            
        else
            t_util:Add(ret, prefab_sc)
        end
    end)

    table.sort(ret, self.SortUnit)
    return ret
end








function g_util.SortUnit(a, b)
    local sa = a:find("_sketch")
    local sb = b:find("_sketch")
    if sa and not sb then
        return true
    elseif not sa and sb then
        return false
    else
        return a < b
    end
end





function g_util.SortSB(a, b)
    local h_a = h_util:GetPrefabAsset(a)
    local h_b = h_util:GetPrefabAsset(b)
    if h_a and not h_b then
        return true
    elseif not h_a and h_b then
        return false
    else
        local sb_a, sb_b = SB[a] or {}, SB[b] or {}
        local sc_a, sc_b = type(sb_a.subcat)=="string" and sb_a.subcat or "",
        type(sb_b.subcat)=="string" and sb_b.subcat or ""
        local t_a, t_b = type(sb_a.type)=="string" and sb_a.type or "",
        type(sb_b.type)=="string" and sb_b.type or ""
        local si_a, si_b = type(sb_a.specialinfo)=="string" and sb_a.specialinfo or "",type(sb_b.specialinfo)=="string" and sb_b.specialinfo or ""
        local m_a, m_b = t_util:GetRecur(m_util:IsModPrefab(a), "modinfo.name"), t_util:GetRecur(m_util:IsModPrefab(b), "modinfo.name")
        m_a = type(m_a)=="string" and "_"..m_a or "!!"
        m_b = type(m_b)=="string" and "_"..m_b or "!!"
        return m_a..si_a..sc_a..t_a..a < m_b..si_b..sc_b..t_b..b
    end
end



function g_util.FilterBuilder(prefabs)
    local ret = {}
    t_util:IPairs(prefabs, function(prefab)
        local prefab_str = prefab
        if prefab:sub(-8) == "_builder" then
            prefab_str = prefab:sub(1, -9)
        end
        if Prefabs[prefab_str] then
            t_util:Add(ret, prefab_str)
        end
    end)
    return ret
end


function g_util.Subcat(subcat)
    return t_util:PairToIPair(SB, function(prefab, line)
        return line.subcat==subcat and prefab
    end)
end


function g_util.SeeMore(title, bodytext)
    return function()
        h_util:CreatePopupWithClose(title, bodytext)
    end
end



function g_util:DebugTurfs()
    local GroundTiles = require("worldtiledefs")
    local turfs = t_util:PairToIPair(WORLD_TILES or {}, function(tile_name, tile_id)
        local prefab = GroundTiles.turf[tile_id] and GroundTiles.turf[tile_id].name
        return prefab and "turf_"..prefab
    end)
    t_util:IPairs(g_util.Subcat("turf"), function(prefab)
        if not table.contains(turfs, prefab) then
            print(prefab)
        end
    end)
    
    
    
end


function g_util.turf_all()
    if not g_util.prefabs.turf_all then
        local map_turfs = {}
        local function add_map_turf(tile_name, tile_id, isold)
            if map_turfs[tile_id] then
                return
            end
            local tile_inv = GroundTiles.turf[tile_id] and GroundTiles.turf[tile_id].name
            local prefab_turf = ("turf_"..(tile_inv or tile_name)):lower()
            local reprefab = r_data.turf_prefix..tile_name
            local inv = Prefabs[prefab_turf] and prefab_turf or r_data.prefab_image[reprefab]
            local name = e_util:GetPrefabName(inv or reprefab)
            local name_got = name~=e_util.NullName
            name = name_got and name or tile_name
            local xml, tex = h_util:GetPrefabAsset(inv)
            map_turfs[tile_id] = {
                name = name,
                hover = name,
                id = tile_id,
                code = tile_name,
                prefab = reprefab,
                inv = inv,
                xml = xml,
                tex = tex,
                isold = isold,
            }
        end
        t_util:Pairs(WORLD_TILES or {}, add_map_turf)
        
        t_util:Pairs(GROUND_NAMES or {}, function(id, name)
            add_map_turf(name, id, true)
        end)

        g_util.prefabs.turf_all = t_util:PairToIPair(map_turfs, function(_, data)
            return data
        end)
        table.sort(g_util.prefabs.turf_all, function(a, b)
            return a.id < b.id
        end)
    end
    return g_util.prefabs.turf_all
end


return g_util
