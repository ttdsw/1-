
local t_util = require "util/tableutil"
local anim = {
    charlie = {
        name = "查理",
        bank = "charlie_basic",
        build = "charlie_basic",
        default = "spawn",
        loop = {                    
            idle = { "spawn", "spawn_out", "cast_pre" },
            cast_idle = "cast_pst",
        },
        play = {                    
            spawn = "idle",
            cast_pre = "cast_idle",
            cast_pst = "idle",
            spawn_out = "idle",
        }
    },
    pigman = {
        name = "猪猪",
        bank = "pigman",
        build = "pig_build",
        default = "idle_loop",
        play = {
            frozen = "frozen_loop_pst",
            idle_creepy = "idle_loop",
            idle_loop = "idle_happy",
            run_pre = "run_loop",
            walk_pre = "walk_loop",
            idle_scared = "idle_creepy",
            idle_angry = "idle_angry",
        }
    },
    dragonfly = {
        name = "龙蝇之年",
        bank = "dragonfly",
        build = "dragonfly_yule_build",
        default = "walk_pre",
        loop = {
            idle = {"hit_large","walk_angry_pre", "walk_pre", "atk"},
            walk = {"walk_angry_pre", "hit_large", "fire_on"},
            walk_angry = {"walk_pre", "hit_large", "atk", "walk_angry_pst", "fire_on"},
            sleep_loop = {"atk", "walk_pre"},
            hit_ground = {"land", "walk_angry_pst"},
            land_idle = {"walk_pre", "sleep_pre", "sleep_pst"}
        },
        play = {
            walk_angry_pre = "walk_angry",
            walk_pre = "walk",
            hit_large = "hit_ground",
            atk = "walk_angry",
            sleep_pre = "sleep_loop",
            land = "land_idle",
            walk_angry_pst = "idle",
            sleep_pst = "idle",
            fire_on = "idle",
        }
    },
    otter = {
        name = "水獭之年",
        bank = "otter_basics",
        build = "otter_build",
        default = "taunt",
        loop = {
            idle = {"attack", "bite", "hit", "taunt", "sleep_pre", "pickup", "eat_pre"},
        },
        play = {
            sleep_pre = "sleep_loop",
            attack = "idle",
            bite = "idle",
            hit = "idle",
            taunt = "idle",
            pickup = "idle",
            eat_pre = "eat_pst",
            sleep_pst = "idle",
            sleep_loop = "sleep_pst",
        }
    }
}
local function FillLoop(id)
    anim[id].loop = anim[id].loop or {}
    local loop_data = anim[id].loop
    t_util:Pairs(anim[id].play, function(_, anim_loop)
        if not loop_data[anim_loop] then
            loop_data[anim_loop] = t_util:PairToIPair(anim[id].play, function (anim_play)
                return anim_play
            end)
        end
    end)
end
FillLoop("pigman")

return anim