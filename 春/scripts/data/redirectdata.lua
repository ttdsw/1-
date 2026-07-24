

local t_util = require "util/tableutil"
local prefab_prefix = "MOD_HUXI_"
local turf_prefix = "MOD_TURF_"
local GroundTiles = require("worldtiledefs")


local deer = STRINGS.NAMES.DEER
local bluegem = STRINGS.NAMES.BLUEGEM
local redgem = STRINGS.NAMES.REDGEM

local prefab_name = {
    deciduousmonster = STRINGS.UI.CUSTOMIZATIONSCREEN.DECIDUOUSMONSTER or "毒桦栗树",
    shadowthrall_centipede_controller = STRINGS.NAMES.SHADOWTHRALL_CENTIPEDE or "巨荒蜈",
    wobster_moonglass_land = STRINGS.NAMES.WOBSTER_MOONGLASS or "月光龙虾",
    deer_blue = deer and bluegem and deer.."("..bluegem..")" or "无眼鹿(蓝宝石)",
    deer_red = deer and redgem and deer.."("..redgem..")" or "无眼鹿(红宝石)",
    moose = STRINGS.UI.CUSTOMIZATIONSCREEN.GOOSEMOOSE or "麋鹿鹅",
    stalker_minion1 = STRINGS.NAMES.STALKER_MINION or "编织暗影",
    stalker_minion2 = STRINGS.NAMES.STALKER_MINION or "编织暗影",
    moose_nesting_ground = STRINGS.NAMES.MOOSENEST1 or "麋鹿鹅巢",
    MOD_HUXI_sculpture_carry = STRINGS.NAMES.SCULPTURE_BISHOPHEAD or "可疑的大理石",
    MOD_HUXI_sculpture_fixed = STRINGS.NAMES.SCULPTURE_KNIGHTBODY or "大理石雕像",
    MOD_HUXI_moon_altar = STRINGS.NAMES.MOON_ALTAR_ROCK_GLASS or "吸引人的结构",
    MOD_HUXI_cave_entrance = STRINGS.NAMES.CAVE_ENTRANCE_OPEN or "洞穴入口",
    archive_orchestrina_base = "月亮启示殿堂",
    MOD_TURF_WAGSTAFF_FLOOR = STRINGS.NAMES.WAGPUNK_FLOOR_KIT or "基底扩展器",
    MOD_TURF_MONKEY_DOCK = STRINGS.NAMES.DOCK_KIT or "码头套装",
    MOD_TURF_IMPASSABLE = "虚空",
    MOD_TURF_DIRT = "空地",
    MOD_TURF_FARMING_SOIL = "耕地",
    MOD_TURF_OCEAN_COASTAL_SHORE = "海岸",
    MOD_TURF_OCEAN_BRINEPOOL = "盐堆",
    MOD_TURF_OCEAN_COASTAL = "浅海",
    MOD_TURF_OCEAN_SWELL = "中海",
    MOD_TURF_OCEAN_ROUGH = "深海",
    MOD_TURF_OCEAN_HAZARDOUS = "危海",
    MOD_TURF_OCEAN_WATERLOG = "水中木",
    MOD_TURF_OCEAN_ICE = "冰岛",
    MOD_TURF_RIFT_MOON = "月能裂隙",
    MOD_TURF_INVALID = "无效",
    
    MOD_TURF_VAULT = "远古圣殿",
    MOD_TURF_FAKE_GROUND = "虚假地块",
    lightninggoatherd = STRINGS.NAMES.LIGHTNINGGOAT.."出生点",
    redpouch_unwrap = "拆红包特效",
}

setmetatable(prefab_name, {
    __index = function(t, k)
        if type(k) == "string" then
            local v = rawget(t, k)
            if v then
                return v
            elseif k:match("^redpouch_[^_]*$") then
                return STRINGS.NAMES.REDPOUCH or "红包"  
            elseif k:match("^deer_antler%d?$") then
                return STRINGS.NAMES.DEER_ANTLER or "无眼鹿角"
            end
        end
    end
})


local prefab_image = {
    statuemaxwell = "statue",
    statueharp = "statue_small",
    cave_entrance = "cave_closed",
    sculpture_rook = "sculpture_rookbody_fixed",
    sculpture_bishop = "sculpture_bishopbody_fixed",
    sculpture_knight = "sculpture_knightbody_fixed",
    statue_marble_muse = "statue_small",
    statue_marble_pawn = "statue_small",
    statueharp_hedgespawner = "statue_small",
    resurrectionstone = "resurrection_stone",
    hermithouse_construction1 = "hermitcrab_home2",
    monkeyqueen = "monkey_queen",
    monkeyisland_portal = "monkey_island_portal",
    rabbithouse = "rabbit_house",
    ruins_statue_mage_spawner = "statue_ruins",
    ruins_statue_mage_nogem_spawner = "statue_ruins",
    ruins_statue_head_spawner = "statue_ruins",
    ruins_statue_head_nogem_spawner = "statue_ruins",
    ancient_altar_broken_spawner = "ancient_altar",
    wormhole_MARKER = "tentacle_pillar",
    oasislake = "oasis",
    atrium_gate = "atrium_gate_active",
    tentacle_pillar_atrium = "tentacle_pillar",
    
    shadowminer = "shadowminer_builder",
    shadowlumber = "shadowlumber_builder",
    shadowdigger = "shadowdigger_builder",
    shadowduelist = "shadowduelist_builder",
    
    hermit_bundle_shells = "hermit_bundle",
    
    wanderingtrader = "station_wanderingtrader",
    wendy_recipe_gravestone = "dug_gravestone",
    
    ticoon = "ticoon_builder",
    MOD_HUXI_sculpture_carry = "sculpture_knighthead",
    MOD_HUXI_sculpture_fixed = "sculpture_rookbody_full",
    MOD_HUXI_moon_altar = "moon_altar_idol_rock",
    watertree_pillar = "oceantree_pillar",
    MOD_HUXI_cave_entrance = "cave_closed",
    cave_exit = "cave_open2",
    archive_lockbox_dispencer = "archive_knowledge_dispensary",
    archive_switch = "archive_power_switch",
    archive_orchestrina_base = "archive_portal",
    ancient_altar = "tab_crafting_table",
    MOD_TURF_WAGSTAFF_FLOOR = "wagpunk_floor_kit",
    MOD_TURF_MONKEY_DOCK = "dock_kit",
    lightninggoatherd = "lightninggoat"
}


t_util:Pairs(WORLD_TILES or {}, function(tile_name, tile_id)
    local tile_def = GroundTiles.turf[tile_id]
    local prefab_inv = tile_def and tile_def.name and "TURF_"..tile_def.name
    
    local str_name = prefab_inv and STRINGS.NAMES[prefab_inv:upper()]
    if str_name then
        prefab_name[turf_prefix..tile_name] = str_name
        prefab_image[turf_prefix..tile_name] = prefab_inv:lower()
    end
end)




local prefabs_tele = {
    dragonfly = "dragonfly_spawner",
    multiplayer_portal = "multiplayer_portal_moonrock",
    beequeen = {'beequeenhive', 'beequeenhivegrown'},
    moose_nesting_ground = "mooseegg",
    antlion = "antlion_spawner",
    terrarium = "terrariumchest",
    MOD_HUXI_cave_entrance = {"cave_entrance", "cave_entrance_open"},
    MOD_HUXI_sculpture_carry = {'sculpture_knighthead', 'sculpture_bishophead','sculpture_rooknose', },
    MOD_HUXI_sculpture_fixed = {'sculpture_knightbody', 'sculpture_bishopbody','sculpture_rookbody', },
    MOD_HUXI_moon_altar = {"moon_altar_rock_glass", 'moon_altar_rock_idol', 'moon_altar_rock_seed'},
    watertree_pillar = "watertree_root",
    waterplant = "waterplant_baby",
    malbatross = "oceanfish_shoalspawner",
    daywalker2 = "junk_pile_big",
    sharkboi = "icefishing_hole",
    tentacle_pillar = "tentacle_pillar_hole",
    archive_lockbox_dispencer = "archive_lockbox",
    ancient_altar = "ancient_altar_broken",
    minotaur = "minotaurchest",
}
local prefab_tele = {}
local list_tele = t_util:PairToIPair(prefabs_tele, function(k, v)
    local t
    if type(v) == "string" then
        t = {k, v}
    elseif type(v) == "table" then
        t = t_util:Add(v, k)
    end
    t_util:IPairs(t or {}, function(prefab)
        
        
        local mt = t_util:IPairFilter(t, function(tp)
            return tp:sub(1,#prefab_prefix)~=prefab_prefix and tp~=prefab and tp
        end)
        if prefab:sub(1,#prefab_prefix)~="_" then
            table.insert(mt, 1, prefab)
        end
        prefab_tele[prefab] = mt
    end)
end)











local prefab_func = {
    deciduousmonster = {
        prefab = "deciduoustree",
        done = "IT:StartMonster(true)"
    },
    klaus = {
        done = "IT:SpawnDeer()"
    },
    meatrack_hermit_multi = {
        done = "local mt=getmetatable(IT)or{} mt.__newindex=function(t,k,v)rawset(t,k,v) if k=='abandoning_task'then v:Cancel() end end"
    }
}







local prefab_scrap = {
    worm_boss = {sketch = "chesspiece_wormboss"},
    alterguardian_phase4_lunarrift = {sketch = "chesspiece_wagboss_lunar"},
    moose = {sketch = "chesspiece_moosegoose"},
    deciduousmonster = {add = "livinglog"},
    leif_sparse = {prefab = "leif"},
    mutatedbearger = {sketch = "chesspiece_bearger_mutated"},
    mutateddeerclops = {sketch = "chesspiece_deerclops_mutated"},
    mutatedwarg = {sketch = "chesspiece_warg_mutated"},
    shadowthrall_centipede_controller = {prefab = "shadowthrall_centipede_head"},
    stalker_atrium = {sketch = "chesspiece_stalker"}, 
    toadstool_dark = {sketch = "chesspiece_toadstool"},
}







local spice_set = {
    lightninggoatherd = {"images/hx_icons1.xml", "spawner_over.tex"}
}











return {
    prefab_image = prefab_image,
    prefab_tele = prefab_tele,
    prefab_name = prefab_name,
    prefab_func = prefab_func,
    prefab_scrap = prefab_scrap,
    prefab_prefix = prefab_prefix,
    turf_prefix = turf_prefix,
    spice_set = spice_set,
}

