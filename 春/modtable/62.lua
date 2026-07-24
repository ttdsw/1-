local save_id, stat_name, boss_str = "huxi_warn", "warndata", "怪物预警"
local default_data = {
    sw = true,
    way = "ann",
    color = "红色"
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local way_default = m_util:IsTurnOn("pos_say")

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegStat(stat_name, boss_str, "怪物预警 高级设置", function()
        return save_data.sw
    end, fn_save("sw"), {
        periodic = function(data, id, worldtime)
            local time = data.value - worldtime
            return time > 0 and {}
        end,
        fn_left = function(data)
            if data.announce then
                u_util:Say(STRINGS.LMB .. " " .. data.announce, nil, "net", nil, true)
            end
        end
    }, {
        screen_data = {{
            id = "way",
            label = "预警提示:",
            hover = "怪物来袭时提示的位置",
            default = fn_get,
            fn = fn_save("way"),
            type = "radio",
            data = {{
                data = "idea",
                description = "跟随系统"
            }, {
                data = "ann",
                description = "宣告出来"
            }, {
                data = "head",
                description = "玩家头顶"
            }, {
                data = "self",
                description = "自己的聊天栏"
            }, {
                data = "null",
                description = "关闭"
            }}
        }, {
            id = "color",
            label = "预警颜色:",
            hover = "怪物来袭时提示的颜色",
            default = fn_get,
            fn = fn_save("color"),
            type = "radio",
            data = (require("data/valuetable")).RGB_datatable
        }},
        priority = 100,
        color = h_util:GetRGB(save_data.color)
    })
end)

local DataBoss = {
    warg = {
        text = "猎犬来袭",
        announce = "猎犬即将来袭！请注意防御！"
    },
    worm = {
        text = "蠕虫来袭",
        announce = "洞穴蠕虫即将来袭！请注意防御！"
    },
    bat = {
        text = "硝石蝙蝠",
        announce = "硝石蝙蝠即将来袭！请注意防御！"
    },
    bearger = {
        text = "熊獾来临",
        announce = "熊獾即将刷新！请离开基地！"
    },
    deerclops = {
        text = "巨鹿来临",
        announce = "独眼巨鹿即将刷新！请离开基地！"
    },
    antlion = {
        text = "蚁狮发怒",
        announce = "蚁狮发起地陷了！请离开基地！"
    },
    cavein_boulder = {
        text = "巨石坠落",
        announce = "蚁狮发怒了！请注意落石！"
    },
    polly_rogershat = {
        text = "海盗来袭",
        announce = "海盗猴入侵了！请注意防御！"
    }
}

local _last_say_time = 0
local function AddWarn(icon)
    return function()
        if (GetTime() - _last_say_time < 20) then
            return
        end
        _last_say_time = GetTime()
        local saver = TheWorld and TheWorld.components and TheWorld.components.hx_saver
        if saver then
            local info = DataBoss[icon]
            local xml, tex = h_util:GetPrefabAsset(icon)
            if info and xml then
                local cd = info.cd or 30
                saver:AddStat(stat_name, icon, {
                    xml = xml,
                    tex = tex,
                    describe = info.text or "",
                    text = info.text or "",
                    value = saver:GetWorldTime() + cd,
                    announce = info.announce
                })
                local way = save_data.way
                if info.announce and way ~= "null" then
                    i_util:DoTaskInTime(1, function()
                        if way == "ann" then
                            u_util:Say(STRINGS.LMB .. " " .. info.announce, nil, "net", nil, true)
                        elseif way == "self" then
                            u_util:Say(boss_str, info.announce, "self", save_data.color, true)
                        elseif way == "head" then
                            u_util:Say(info.announce, nil, "head", save_data.color, true)
                        else
                            u_util:Say(boss_str, info.announce, nil, save_data.color, true)
                        end
                    end)
                end
            end
            if not saver:HasStatUI(stat_name, icon) then
                saver:SetTimerConfig()
            end
        end
    end
end

local function QuickAdd(sound, num, icon)
    for i = 1, num do
        AddPrefabPostInit(sound .. "warning_lvl" .. i, AddWarn(icon))
    end
end
QuickAdd("hound", 4, "warg")
QuickAdd("worm", 4, "worm")
QuickAdd("acidbatwave", 1, "bat")
QuickAdd("bearger", 4, "bearger")
QuickAdd("deerclops", 4, "deerclops")

for i = 1, 3 do
    AddPrefabPostInit("sinkhole_warn_fx_" .. i, function(inst)
        inst:DoTaskInTime(0, function()
            
            if not t_util:GetRecur(TheWorld, "state.issummer") or
                e_util:FindEnt(inst, {"um_scorpionhole", "um_scorpion"}, 4) then
                return m_util:print("不妥协过滤！")
            end
            AddWarn("antlion")()
        end)
    end)
end
AddPrefabPostInit("cavein_debris", AddWarn("cavein_boulder"))
AddPrefabPostInit("piratewarningsound", AddWarn("polly_rogershat"))
