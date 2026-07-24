





local forest_terr = {
    {
        path = "DefaultPigking",
        room = "DefaultPigking",
        icon = "pigking",
        only = true,
        roomicon = "pigking"
    },
    {
        path = "DragonflyArena",
        icon = {"dragonfly_spawner", "lava_pond"},
        only = true,
        roomicon = "dragonfly",
        room = "DragonflyArena",
    }, 
    {
        path = {"Charlie1", "Charlie2"},
        icon = {"charlie_stage_post","statueharp_hedgespawner"},
        only = true,
    }, 
    {
        
        path = {"Dev Graveyard"},
        icon = {"marblepillar", "statuemaxwell", },
        only = true,
    }, 
    {
        path = {"Balatro"},
        icon = {"balatro_machine", },
        only = true,
    }, 
    {
        path = {"Chessy_1", "Chessy_2", "Chessy_3", "Chessy_4", "Chessy_5", "Chessy_6", },
        icon = {"marbletree", "knight", "bishop", "gears", "statuemaxwell", "rook", "backpack", "marblepillar", 
               "statueharp", "sculpture_rook", "statue_marble_muse", "statue_marble_pawn", "sculpture_bishop",
               "sculpture_knight"},
        only = true,
        deny = {WORLD_TILES.CARPET, WORLD_TILES.CHECKER},
    }, 
    {
        path = {"Maxwell1", "Maxwell2", "Maxwell3", "Maxwell4", "Maxwell5", "Maxwell6", "Maxwell7", },
        icon = {"statuemaxwell", "marbletree", "knight", "bishop", "gears", "statuemaxwell", "rook", "backpack", "marblepillar", 
               "statueharp", "sculpture_rook", "statue_marble_muse", "statue_marble_pawn", "sculpture_bishop",
               "sculpture_knight"},
        only = true,
        deny = {WORLD_TILES.CARPET, WORLD_TILES.CHECKER},
    }, 
    {
        path = {"Sculptures_1", "Sculptures_2", "Sculptures_3", "Sculptures_4", "Sculptures_5", },
        icon = {"sculpture_rook", "marbletree", "knight", "bishop", "gears", "rook", "backpack", "marblepillar", 
               "statueharp",  "statue_marble_muse", "statue_marble_pawn", "sculpture_bishop",
               "sculpture_knight"},
        only = true,
        deny = {WORLD_TILES.CARPET, WORLD_TILES.CHECKER},
    }, 
    {
        path = "HermitcrabIsland",
        room = "HermitcrabIsland",
        icon = "hermithouse_construction1",
        only = true,
        roomicon = "hermithouse_construction1"
    },
    {
        path = "AntlionSpawningGround",
        room = "LightningBluffAntlion",
        icon = "antlion_spawner",
        only = true,
        roomicon = "antlion"
    },
    {
        path = "CaveEntrance",
        icon = "cave_entrance",
        deny = {WORLD_TILES.DIRT}, 
        layer = 1,
        alone = true,
    },
    {
        path = "ResurrectionStone",
        icon = "resurrectionstone",
        deny = {WORLD_TILES.WOODFLOOR},
        layer = 1,
        alone = true,
    },
    
    
    
    
    
    
    
    
    {
        path = "junk_yard",
        icon = {"junk_pile_big", "junk_pile"},
        only = true,
        deny = {WORLD_TILES.DIRT},

    },
    {
        path = "MoonbaseOne",
        room = "MoonbaseOne",
        icon = "moonbase",
        only = true,
        roomicon = "moonbase"
    },
    {
        path = "Oasis",
        room = "LightningBluffOasis",
        icon = "oasislake",
        only = true,
        roomicon = "oasis"
    },
}
local cave_terr = {
    {
        path = "ResurrectionStone",
        icon = "resurrectionstone",
        deny = {WORLD_TILES.WOODFLOOR},
        layer = 1,
        alone = true,
    },
    {
        path = "TentaclePillar",
        icon = "wormhole_MARKER",
        deny = {WORLD_TILES.MARSH},
        layer = 1
    },
    {
        path = {"RabbitCity", "RabbitHermit", "RabbitTown"},
        icon = "rabbithouse",
        alone = true,
    },
    {
        path = "WalledGarden",
        icon = {"minotaur_spawner", "ruins_statue_mage_spawner"},
        only = true,
        room = "RuinedGuarden",
        room_icon = "minotaur",
    },
    {
        path = {"AltarRoom", "BrokenAltar", "Barracks2", "SacredBarracks", "Spiral", "MilitaryEntrance"},
        icon = {"chessjunk_spawner", "ancient_altar_spawner", "sacred_chest","ruins_statue_head_spawner", 
            "ruins_statue_head_nogem_spawner","ruins_statue_mage_nogem_spawner", "ruins_statue_mage_spawner", "ancient_altar_broken_spawner",
            "bishop_nightmare_spawner", "rook_nightmare_spawner", "knight_nightmare_spawner"},
        alone = true,
    },
    {
        path = "map/static_layouts/rooms/atrium_end/atrium_end",
        icon = "atrium_gate",
        only = true,
    },
    {
        path = {"TentaclePillarToAtrium", "TentaclePillarToAtriumOuter"},
        icon = {"tentacle_pillar_atrium", "bishop_nightmare"},
        only = true,
    },
    
}


local forest_node ={
    {
        room = "Waspnests",
        icon = "wasphive",
    },
    {
        all = "WalrusHut_",
        icon = "walrus_camp",
    },
    {
        room = "SpiderVillage",
        icon = "spidereggsack",
    },
    {
        room = "PigVillage",
        icon = "pighouse",
    },
    {
        room = "BeefalowPlain",
        icon = "beefalo",
    },
    {
        room = "MandrakeHome",
        icon = "mandrake",
    },
    {
        room = "HoundyBadlands",
        icon = "houndmound",
    },
    {
        room = "Graveyard",
        icon = "gravestone",
    },
    {
        room = "LightningBluffLightning",
        icon = "lightninggoat",
    },
    {
        room = "LightningBluffOasis",
        icon = "oasis",
    },
    {
        room = "LightningBluffAntlion",
        icon = "antlion",
    },
    {
        room = "MoonIsland_Forest",
        icon = "moon_tree",
    },
    {
        room = "MoonIsland_Baths",
        icon = "hotspring",
    },
    {
        room = "MoonIsland_Meadows",
        icon = "moonglass_rock",
    },
    {
        room = "MoonIsland_Mine",
        icon = "rock_moon",
    },
    {
        room = "MoonIsland_Beach",
        icon = "bullkelp_plant",
    },
    {
        room = "MoonIsland_IslandShard",
        icon = "driftwood_log",
    },
    {
        room = "Pondopolis",
        icon = "frog",
    },
    {
        room = "BeeQueenBee",
        icon = "beequeenhivegrown",
    },
    {
        room = "MooseGooseBreedingGrounds",
        icon = "mooseegg",
    },
    {
        room = "PigKingdom",
        icon = "pigking",
    },
    {
        room = "MagicalDeciduous",
        icon = "glommer",
    },
    {
        room = "ForestMole",
        icon = "mole",
    },
    {
        room = "MoonbaseOne",
        icon = "moonbase",
    },
    {
        room = "DragonflyArena",
        icon = "dragonfly",
    },
    {
        room = "MonkeyIsland",
        icon = "monkey_queen",
    },
    {
        room = "HermitcrabIsland",
        icon = "hermithouse_construction1",
    },
    {
        all = "Squeltch:BG_",
        icon = "tentacle",
    },

}

local cave_node = {
    {
        all = "START",
        icon = "multiplayer_portal",
    },
    {
        task = {"ToadStoolTask1", "ToadStoolTask2", "ToadStoolTask3"},
        icon = "toadstool_cap",
    },
    {
        room = {"SlurtlePlains", "SlurtleCanyon", "BatsAndSlurtles"},
        icon = "slurtlehole",
    },
    {
        room = "CaveExitRoom",
        icon = "cave_open2",
    },
    {
        room = "BrokenAltar",
        icon = "ancient_altar_broken",
    },
    {
        room = "Altar",
        icon = "ancient_altar",
    },
    {
        room = "Bishops",
        icon = "bishop_nightmare",
    },
    {
        room = "SacredBarracks",
        icon = "rook_nightmare",
    },
    {
        room = "Barracks",
        icon = "knight_nightmare",
    },
    {
        room = {"MudWithRabbit", "RabbitTown", "RabbitCity", "RabbitArea", "GreenMushRabbits"},
        icon = "rabbithouse",
    },
    {
        room = "WormPlantField",
        icon = "flower_cave_double",
    },
    {
        room = "LightPlantField",
        icon = "flower_cave_triple",
    },
    {
        room = {"RedMushPillars", "RedMushForest", "BGRedMush"},
        icon = "mushtree_medium",
    },
    {
        room = {"BGBlueMush", "BlueMushForest", "BlueMushMeadow", "BlueSpiderForest"},
        icon = "mushtree_tall",
    },
    {
        room = {"GreenMushForest", "GreenMushSinkhole", "GreenMushMeadow", "GreenMushPonds", "BGGreenMush"},
        icon = "mushtree_small",
    },
    {
        room = {"MoonCaveForest", "MoonMushForest_entrance", "MoonMushForest",},
        icon = "mushtree_moon",
    },
    {
        room = "FernyBatCave",
        icon = "batcave",
    },
    {
        room = {"SpillagmiteMeadow", "SpillagmiteForest"},
        icon = "stalagmite",
    },
    {
        room = {"DropperDesolation", "DropperCanyon"},
        icon = "spider_dropper",
    },
    {
        room = {"RockyHatchingGrounds", "RockyPlains"},
        icon = "rocky",
    },
    {
        room = "Vacant",
        icon = "monkeybarrel",
    },
    {
        room = "SinkholeOasis",
        icon = "pond",
    },
    {
        room = {"SpidersAndBats", "BGSpillagmiteRoom", "SpillagmiteForest"},
        icon = "spiderhole",
    },
    {
        room = "WetWilds",
        icon = "pond_cave",
    },
    {
        room = "LichenLand",
        icon = "lichen",
    },
    {
        room = "LichenMeadow",
        icon = "worm",
    },
    {
        room = "RuinedGuarden",
        icon = "minotaur_spawner",
    },
    
    
    
    
    
}




local foreset_tile = {
    OCEAN_BRINEPOOL = {
        range = 12,
        icon = "saltstack",
    },
    OCEAN_WATERLOG = {
        icon = "oceantree_pillar",
    },
    
    
    
    
    
    OCEAN_ICE = {
        icon = "sharkboi",
        getnew = true,
    },
}
local cave_tile = {
    ARCHIVE = {
        range = 12,
        icon = "archive_orchestrina_main",
    }
}

local order_icon = {
    "lunarrift_portal", "wasphive", "walrus_camp", "spidereggsack", "toadstool_cap",
    "sharkboi", "oceantree_pillar", "saltstack",
}

local icon_chs = {
    wasphive = "杀人蜂聚集",
    spidereggsack = "蜘蛛矿区",
    pighouse = "猪人村落",
    beefalo = "牛群",
    gravestone = "墓地",
    lightninggoat = "伏特羊群",
    oasis = "绿洲",
    antlion = "蚁狮刷新点",
    moon_tree = "月树聚集",
    rock_moon = "月岩",
    driftwood_log = "附属月岛",
    frog = "青蛙池塘",
    mooseegg = "鹿鸭巢",
    monkey_queen = "猴子岛",
    hermithouse = "珍珠的家",
    toadstool_cap = "毒菌蟾蜍刷新点",
    cave_open2 = "楼梯",
    bishop_nightmare = "梦魇聚集点1", 
    rook_nightmare = "梦魇聚集点2", 
    knight_nightmare = "梦魇聚集点3", 
    rabbithouse = "兔人聚集点", 
    flower_cave_double = "荧光果平原",
    flower_cave_triple = "亮荧光果平原",
    mushtree_medium = "红蘑菇林",
    mushtree_tall = "蓝蘑菇林",
    mushtree_small = "绿蘑菇林",
    mushtree_moon = "月亮蘑菇林",
    dragonfly_spawner = "龙蝇",
    marblepillar = "开发者墓园",
    marbletree = "棋子彩蛋",
    sculpture_rook = "三基佬彩蛋",
    statuemaxwell = "麦斯威尔彩蛋",
    hermithouse_construction1 = "珍珠的家",
    antlion_spawner = "蚁狮生成点",
    cave_entrance = "洞穴入口",
    resurrectionstone = "试金石",
    junk_pile_big = "垃圾堆",
    oasislake = "绿洲",
    wormhole_MARKER = "触手",
    minotaur_spawner = "远古守护者",
    chessjunk_spawner = "梦魇发条怪",
    atrium_gate = "中庭",
    tentacle_pillar_atrium = "中庭触手",
    saltstack = "盐矿",
    oceantree_pillar = "水中木",
    lunarrift_portal = "辉煌裂隙",
    archive_orchestrina_main = "档案馆",
}

return {
    terr = {
        forest = forest_terr,
        cave = cave_terr,
    },
    node = {
        forest = forest_node,
        cave = cave_node,
    },
    tile = {
        forest = foreset_tile,
        cave = cave_tile,
    },
    order = order_icon,
    chs = icon_chs,
}