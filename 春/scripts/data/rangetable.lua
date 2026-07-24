local t_util = require "util/tableutil"



local attack_range = {
	{
		prefabs = {"ghost",},
		rotary = {1.5},
	}, 
	{
		prefabs = {
					"lightninggoat", 
					"krampus",
					"crawlingnightmare", 
					"nightmarebeak", 
					"deer_blue", 
					"deer_red", 
					"birchnutdrake", 
					"moonpig", "pigguard", "mermguard","pigman", "bunnyman", "merm",
					"koalefant_summer", "koalefant_winter", "grassgator", "beefalo", 
					"fruitdragon", "gnarwail","spat",
					
					"frog", "knight","knight_nightmare",
					"powder_monkey",
					"prime_mate",
					"monkey",
					"houndcorpse", "hound", "icehound", "firehound", "mutatedhound", "clayhound", "hedgehound",
					"spider_healer", "spider_moon", "spider_dropper", "spider", "spider_warrior", "spider_hider", "spider_spitter",
					
					"terrorbeak","crawlinghorror","otter",
				},
		rotary = {3},
	},
	{
		prefabs = {"leif","leif_sparse",},
		rotary = {[3] = function (circle, ent, scale)
			circle:SetFixedRadius(3*scale+0.5)
		end},
	},
	{
		prefabs = {"koalefant_summer", "koalefant_winter",},
		rotary = {5},
	}, 
	{
		prefabs = {"rocky","eyeofterror_mini"},
		rotary = {4},
	}, 
	{
		prefabs = {"shark"},
		rotary = {4},
	}, 
	{
		prefabs = {"tentacle","flup"},
		rotary = {[4] = '绿色'},
		always = true,
	},
    {
		prefabs = {"lunarthrall_plant"},	
		rotary = {4},
	},
	{
		prefabs = {"lunarthrall_plant_vine_end"},	
		rotary = {3},
		quick = true,
	},
	{
		prefabs = {"deerclopseyeball_sentryward"},	
		rotary = {3},
	},
	
	{
		prefabs = {"daywalker"},
		rotary = {6},
	}, 
	{
		prefabs = {"deerclops"},
		rotary = {12},
	}, 
	{
		prefabs = {"warglet"},
		rotary = {3},
	}, 
	{
		prefabs = {"klaus"},
		rotary = {[TUNING.KLAUS_HIT_RANGE] = function (circle, ent, scale)
			circle:SetFixedRadius(TUNING.KLAUS_HIT_RANGE * scale / 1.2 +0.5)
		end,
		
	}
	},
	{
		prefabs = {"minotaur"},
		rotary = {4.1-0.5,4.1+0.5},
	},
	{
		prefabs = {"stalker","stalker_forest","stalker_atrium"},
		rotary = {2.9,10},
	},
	{
		prefabs = {"shadow_knight"},
		rotary = {[TUNING.SHADOW_KNIGHT.ATTACK_RANGE_LONG] = function (circle, ent, scale)
			if scale == 2.5 then
				circle:SetFixedRadius(6 + 0.5)
			else
				circle:SetFixedRadius(TUNING.SHADOW_KNIGHT.ATTACK_RANGE_LONG*scale + 0.5)
			end
		end},
	},
	{
		prefabs = {"shadow_rook"},
		rotary = {[TUNING.SHADOW_ROOK.HIT_RANGE] = function (circle, ent, scale)
			circle:SetFixedRadius(TUNING.SHADOW_ROOK.HIT_RANGE * scale+0.5)
		end},
	},
	{
		prefabs = {"shadow_bishop"},
		rotary = {[TUNING.SHADOW_BISHOP.HIT_RANGE] = function(circle, ent, scale)
			circle:SetFixedRadius(TUNING.SHADOW_BISHOP.HIT_RANGE * scale+0.5)
		end, [0] = function (circle, ent, scale)
			local level = t_util:GetElement(TUNING.SHADOW_BISHOP.LEVELUP_SCALE, function (level, lsc)
				return lsc > (scale - 0.2) and level
			end)
			if level then
				circle:SetFixedRadius(TUNING.SHADOW_BISHOP.ATTACK_RANGE[level]+0.5)
			end
		end}
	},
	{
		prefabs = {"alterguardian_phase2",},
		rotary = {4.5,}
	}, 
	{
		prefabs = {"alterguardian_phase3",},
		rotary = {TUNING.ALTERGUARDIAN_PHASE3_STAB_RANGE},
	}, 
	
	
	{
		prefabs = {"dirtpile"},
		rotary = {[2] = '蓟色'},
		always = true,
	},
	
	{
		prefabs = {"bearger"},
		rotary = {TUNING.BEARGER_MELEE_RANGE+1},		
	},
	{
		prefabs = {"mutatedbearger"},
		rotary = {TUNING.BEARGER_MELEE_RANGE+3},		
	},
	{
		prefabs = {"mutatedwarg"},
		rotary = {1.7+3+3, TUNING.WARG_ATTACKRANGE},
	},
	{
		prefabs = {"blackbear",},	
		rotary = {6},
	},
	{
		prefabs = {"rhino3_red",},	
		rotary = {4.2},
	},
	{
		prefabs = {"rhino3_blue",},	
		rotary = {4.2},
	},
	{
		prefabs = {"rhino3_yellow",},	
		rotary = {4.2},
	},
	{
		prefabs = {"myth_goldfrog",},	
		rotary = {7},
	},
	{
		prefabs = {"myth_small_goldfrog",},	
		rotary = {3},
	},
	{
		prefabs = {"myth_nian",},	
		rotary = {4},
	},
	{
		prefabs = {"siving_thetree",},	
		rotary = {25},
		always = true,
	},
	{
		prefabs = {"siving_foenix", "siving_moenix", "ruinsnightmare"},	
		rotary = {3.5},
	},
	{
		prefabs = {"elecarmet",},	
		rotary = {6, 20},
	}, 
	
	{
		prefabs = {	
					"snowmong",
					"knook",
					"bight",
					"shockworm",
					"viperworm",
					"glacialhound",
					"lightninghound",
					"magmahound",
					"sporehound",
					"scorpion",
					"spider_trapdoor",
					"ancient_trepidation",
					"bushcrab",
					},
		rotary = {3},
	},
	{
		prefabs = {"hoodedwidow",},	
		rotary = {5},
	}, 
	{
		prefabs = {"moonmaw_dragonfly",},	
		rotary = {5},
	}, 
	{
		prefabs = {"moonmaw_lavae",},	
		rotary = {2},
	}, 
	{
		prefabs = {"mothergoose",},	
		rotary = {5.5},
	}, 
	{
		prefabs = {"mock_dragonfly",},	
		rotary = {4},
	}, 
	{
		prefabs = {"Roship",},	
		rotary = {12},
	}, 
	{
		prefabs = {"viperling",},	
		rotary = {1.5},
	},
	{
		prefabs = {"creepingfear",},	
		rotary = {4},
	}, 
	{
		prefabs = {"dreadeye",},	
		rotary = {2},
	}, 
	{
		prefabs = {"ancient_trepidation_arm",},	
		rotary = {4},
	}, 
	{
		prefabs = {"toadstool_dark",}, 
		rotary = {8},
	}, 
	{
		prefabs = {"crabking_claw",}, 
		rotary = {TUNING.CRABKING_CLAW_ATTACKRANGE},
	}, 
	
	{
		prefabs = {"medal_spike"},
		rotary = {1.1},
		quick = true,
	},
	{
		prefabs = {"medal_guard"},
		rotary = {1.5},
	},
	{
		prefabs = {"medal_origin_flowertrap"},
		rotary = {2.75},
		quick = true,
	},{
		prefabs = {"medal_naughty_krampus", "medal_rage_krampus",},
		rotary = {3},
	},
	{
		prefabs = {"medal_beequeen"},
		rotary = {4},
	},
	{
		prefabs = {"medal_gestalt", "medal_origin_beetle"},
		rotary = {5},
	},{
		prefabs = {"medal_origin_mushgnome"},
		rotary = {3, 15},
	},{
		prefabs = {"medal_origin_spider"},
		rotary = {6},
	},{
		prefabs = {"medal_origin_tree_guard_vine_end", "medal_origin_tree_root"},
		rotary = {3},
		quick = true,
	},{
		prefabs = {"medal_shadowthrall_screamer"},
		rotary = {8,12},
	},
}
local attack_auto = {
	"TALLBIRD", "BUZZARD", "TEENBIRD", "SQUID","SLURTLE",
	"SPIDER_WATER", "TENTACLE_PILLAR_ARM","WORM",
	"CATCOON","SLURPER","WALRUS",
	
	"MOSSLING","BEEGUARD","MOOSE",
	"BEEQUEEN",
	"DEERCLOPS","LORDFRUITFLY","WARG","SPIDERQUEEN","MALBATROSS",
	"DRAGONFLY",

	
	"EYEPLANT",
	"shadowthrall_hands","shadowthrall_horns","shadowthrall_wings",
}
local format_auto = {"%s_ATTACK_DIST", "%s_HIT_RANGE", "%s_ATTACK_RANGE", "%s_ATTACKRANGE"}

t_util:IPairs(attack_auto, function (prefab)
    prefab = prefab:upper()
    local range = t_util:IGetElement(format_auto, function (str)
        return TUNING[str:format(prefab)]
    end)
    if type(range)=="number" then
        table.insert(attack_range, {prefabs = {prefab}, rotary = {range}})
    end
end)

local target_range = {
	{
		prefabs = {"spore_moon"},
		rotary = {3},
	},{
		prefabs = {"lightninggoat"},
		rotary = {8},
	},
	{
		prefabs = {"bishop_nightmare", "rook_nightmare"},
		rotary = {12},
	},{
		prefabs = {"knight_nightmare", "slurtle",},
		rotary = {10},
	},{
		prefabs = {"wasphive"},
		rotary = {[10] = '棕色'},
	},{
		prefabs = {"pigtorch"},
		rotary = {[8] = '棕色'},
	},
	
	{
		prefabs = {"klaus", "dragonfly", "shadow_rook", "shadow_knight", "shadow_bishop"},
		rotary = {15},
	},
	{
		prefabs = {"malbatross"},
		rotary = {[3] = '绿色'},
	},
	{
		prefabs = {"claywarg", "gingerbreadwarg"},
		rotary = {[4] = '绿色'},
	},
	{
		prefabs = {"archive_centipede"},
		rotary = {5},
	},
	{
		prefabs = {"mushroombomb", "mushroombomb_dark"},
		rotary = {3.5},
		quick = true,
	},
	{
		prefabs = {"alterguardian_phase3trap",},
		rotary = {[TUNING.ALTERGUARDIAN_PHASE3_TRAP_AOERANGE]='红色'},
		quick = true,
	}, 
	{
		prefabs = {"eyeofterror", "twinofterror1","twinofterror2"},
		rotary = {3},
	}, 
	
	
	
	
	
	{
		prefabs = {"alterguardian_phase1",},
		rotary = {4.25},
	}, {
		prefabs = {"bigshadowtentacle"},
		rotary = {[4]= '呼吸黄'},				
		quick = true,
		always = true,
	},{
		prefabs = {"mutatedbearger"},
		rotary = {TUNING.MUTATED_BEARGER_TARGET_RANGE},
	},
	{
		prefabs = {"mutatedwarg"},
		rotary = {TUNING.WARG_TARGETRANGE},
	},
	{
		prefabs = {"mutateddeerclops"},
		rotary = {5.5},		
	},

	
	{
		prefabs = {"daywalker2"},
		rotary = {TUNING.DAYWALKER2_TACKLE_RANGE},
	}, {
		prefabs = {"rabbitking_aggressive"},
		rotary = {TUNING.RABBITKING_ABILITY_DROPKICK_SPEED * TUNING.RABBITKING_ABILITY_DROPKICK_MAXAIRTIME},
	},
	
	
	
	
	{
		prefabs = {"medal_origin_cactus"},
		rotary = {[5] = '棕色'},
	},
}
local target_auto = {
	"WALRUS", "KNIGHT", "BISHOP", "ROOK", "SLURTLE",
	"SPAT", "WORM", 
	
	
	"ALTERGUARDIAN_PHASE3",
	
	"MINOTAUR", 
}

t_util:IPairs(target_auto, function (prefab)
    prefab = prefab:upper()
    local range = t_util:IGetElement({"%s_TARGET_DIST", "%s_TARGETRANGE"}, function (str)
        return TUNING[str:format(prefab)]
    end)
    if type(range)=="number" then
        table.insert(target_range, {prefabs = {prefab}, rotary = {range}})
    end
end)


local track = {
	klaus_sack = "红色",
	malbatross = "红色",
	beequeenhivegrown = "金黄色",
	antlion = "红色",
	greengem = "绿色",
	yellowgem = "金黄色",
	livingtree = "棕色",
	livingtree_halloween = "棕色",
	terrariumchest = "紫色",

	
	ia_messagebottle = "红色",
	coral_brain_rock = "红色",
	whale_bubbles = "红色",
	dubloon = "金黄色",
	
	
	musha_treasure2 = "紫色",

	
	rock_moon_shell = "蓝色",
	mushgnome = "棕色",

	
	seeds = "绿色",
}

local hover = {
	
	panflute = TUNING.PANFLUTE_SLEEPRANGE,
	eyeturret = TUNING.EYETURRET_RANGE+3,
	wortox_soul = TUNING.WORTOX_SOULHEAL_RANGE,
	
	book_tentacles = 8, 		
	book_birds = 10,
	book_brimstone = 15,		
	book_sleep = 30,			
	book_gardening = 30,
	book_horticulture = 30,
	book_horticulture_upgraded = 30,
	book_silviculture = 30,
	book_fish = 10,				
	book_fire = TUNING.BOOK_FIRE_RADIUS,
	book_web = TUNING.BOOK_WEB_GROUND_RADIUS,
	book_temperature = TUNING.BOOK_TEMPERATURE_RADIUS,
	book_light = 3,
	book_light_upgraded = 3,
	book_rain = 4,
	book_research_station = TUNING.BOOK_RESEARCH_STATION_RADIUS,
	
	gunpowder = TUNING.GUNPOWDER_RANGE,
	moon_altar = TUNING.MOON_ALTAR_ESTABLISH_LINK_RADIUS,
	
	leif_idol = TUNING.LEIF_IDOL_SPAWN_RADIUS,
	deerclopseyeball_sentryward =  TUNING.DEERCLOPSEYEBALL_SENTRYWARD_RADIUS,
    voidcloth_umbrella = 16,	
	phonograph = 8,	
	singingshell_octave3 = 2,	
	singingshell_octave4 = 2,	
	singingshell_octave5 = 2,	
	firesuppressor = TUNING.FIRE_DETECTOR_RANGE,
	lighter = 2.5,

	spider_whistle = TUNING.SPIDER_WHISTLE_RANGE,
	storage_robot = TUNING.STORAGE_ROBOT_WORK_RADIUS,
	winona_storage_robot = TUNING.WINONA_STORAGE_ROBOT_WORK_RADIUS,
}

local click = {
	firesuppressor = TUNING.FIRE_DETECTOR_RANGE,
	winona_catapult =  TUNING.WINONA_CATAPULT_MAX_RANGE,
	lightning_rod = 40,
	oceantree = TUNING.SHADE_CANOPY_RANGE_SMALL,
	oceantreenut = TUNING.SHADE_CANOPY_RANGE_SMALL,
	oceantree_pillar = TUNING.SHADE_CANOPY_RANGE_SMALL,
	winch = TUNING.SHADE_CANOPY_RANGE_SMALL,
	watertree_pillar = TUNING.SHADE_CANOPY_RANGE,
	eyeturret = TUNING.EYETURRET_RANGE+3,
	winona_spotlight = TUNING.WINONA_SPOTLIGHT_MAX_RANGE + TUNING.WINONA_SPOTLIGHT_MIN_RANGE,
	moon_fissure = TUNING.MOON_ALTAR_ESTABLISH_LINK_RADIUS,
	moon_altar = TUNING.MOON_ALTAR_ESTABLISH_LINK_RADIUS,
	mushroom_light = 11,		
	mushroom_light2 = 11,		
	support_pillar = TUNING.QUAKE_BLOCKER_RANGE,
	support_pillar_scaffold = TUNING.QUAKE_BLOCKER_RANGE,
	support_pillar_dreadstone = TUNING.QUAKE_BLOCKER_RANGE,
	support_pillar_dreadstone_scaffold = TUNING.QUAKE_BLOCKER_RANGE,
	leif_idol = TUNING.LEIF_IDOL_SPAWN_RADIUS,
	deerclopseyeball_sentryward = TUNING.DEERCLOPSEYEBALL_SENTRYWARD_RADIUS,
    dragonflyfurnace = 9.5,	
	lunarthrall_plant = {30, 12,	
	},
    
	voidcloth_umbrella = 16,	
	
	moonbase = 8,	
	lava_pond = 10,	
	lighter = 2.5,

	
	junk_pile_big = {16.8, 22.8},
	daywalker2 = 12,
	toadstool_cap = {TUNING.TOADSTOOL_AGGRO_DIST, 28},

	scarecrow = TUNING.BIRD_CANARY_LURE_DISTANCE,
	trap_starfish = 4,
	storage_robot = TUNING.STORAGE_ROBOT_WORK_RADIUS,
	winona_storage_robot = TUNING.WINONA_STORAGE_ROBOT_WORK_RADIUS,
}

local placer = {
	lightning_rod_placer = 40,
	eyeturret_item_placer = TUNING.EYETURRET_RANGE+3,
	mushroom_light_placer = 11,		
	mushroom_light2_placer = 11,		
    dragonflyfurnace_placer = 9.5,	
	winch_placer = TUNING.SHADE_CANOPY_RANGE_SMALL,
	deerclopseyeball_sentryward_kit_placer = TUNING.DEERCLOPSEYEBALL_SENTRYWARD_RADIUS,
	
	scarecrow_placer = TUNING.BIRD_CANARY_LURE_DISTANCE,
	dug_trap_starfish_placer = 4,
	
}

return {
    attack_range = attack_range,
	target_range = target_range,
	track_range = track,
	hover_range = hover,
	click_range = click,
	placer_range = placer,
}