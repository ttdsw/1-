local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local f_util = require "util/fn_hxcb"
local e_util = require "util/entutil"
local save_data = f_util.save_data
local load_data = f_util.load_data
local m_util = require "util/modutil"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local role_stats = require "data/hx_cb/stats/role"
local lmb, rmb = STRINGS.LMB, "\n"..STRINGS.RMB
local code_range_delete = 'local pos=_U_:GetPosition()for _,o in ipairs(TheSim:FindEntities(pos.x,pos.y,pos.z,{range_delete},nil,{"FX","DECOR","INLIMBO","NOCLICK","multiplayer_portal"}))do if not o:HasTag("player")or o.userid==""then print(o.prefab)o:Remove()end end '
local c_util = require "util/calcutil"


local LS = {
    size_label = 25,
    size_text = 24,
    space_text = 10,
}

function LS:ALabel(str)
    str = str .. ": "
    local text = Text(DEFAULTFONT, self.size_label, str)
    local w, h = text:GetRegionSize()
    return {
        ui = text,
        shift = w,
        height = self.size_label,
    }
end

function LS:ATextBtn(str)
    local btn = TextBtn()
    btn:SetTextSize(self.size_text)
    btn:SetText(str)
    btn:SetTextFocusColour({0,1,1,1})
    local w, h = btn:GetSize()
    return {
        ui = btn,
        shift = w + self.space_text,
        height = h,
    }
end



function LS:AStat(data, size_stat)
    size_stat = size_stat or 38
    local xml, tex = h_util:GetPrefabAsset(data.icon, true)
    local w
    if xml:find("scrapbook_icons") or (xml:find("hx_icons2") and tex:find("icon_badge_")) then
        w = Image(xml, tex)
    else
        w = Image("images/hx_icons2.xml", "icon_badge_pure.tex")
        local icon = w:AddChild(Image(xml, tex))
        icon:ScaleToSize(size_stat, size_stat)
    end
    w:ScaleToSize(size_stat, size_stat)
    w:SetHoverText(data.hover, { offset_y = 2*size_stat })
    h_util:BindMouseClick(w, {
        [MOUSEBUTTON_LEFT] = function(ui)
            if data.left then
                data.left()
            end
        end,
        [MOUSEBUTTON_RIGHT] = function(ui)
            if data.right then
                data.right()
            end
        end,
    }, {sound = "double"})
    return w
end


function LS:LineTextBtn(label_str, btns)
    local ps = {}
    local plabel = self:ALabel(label_str)
    table.insert(ps, plabel)
    t_util:IPairs(btns, function(btn)
        if btn.tagnot and TheWorld and TheWorld:HasTag(btn.tagnot) then
            return
        end
        if btn.text then
            local meta = btn.meta or {}
            local pbtn = self:ATextBtn(subfmt(btn.text, meta))
            if btn.hover then
                local hover = subfmt(btn.hover, meta)
                pbtn.ui.image:SetHoverText(hover, {offset_y = hover:find("\n") and 3*self.size_text or 2*self.size_text})
            end
            h_util:BindMouseClick(pbtn.ui, {
                [MOUSEBUTTON_LEFT] = btn.left,
                [MOUSEBUTTON_RIGHT] = btn.right,
            }, {sound = "double"})
            table.insert(ps, pbtn)
        end
    end)

    local w = Widget("line_textbtns")
    local pos_x, h_max = 0, 0
    t_util:IPairs(ps, function(p)
        w:AddChild(p.ui)
        local half = (p.shift or 0) / 2
        pos_x = pos_x + half
        h_max = math.max(h_max, p.height or 0)
        p.ui:SetPosition(pos_x, 0)
        pos_x = pos_x + half
    end)
    return {
        ui = w,
        height = h_max,
    }
end

function LS:PackLines(...)
    local w = Widget("lines")
    local h = 0
    t_util:Pairs({...}, function(_, line)
        if line and line.ui then
            
            local half = (line.height or 0)/2
            h = h - half
            line.ui:SetPosition(0, h)
            w:AddChild(line.ui)
            h = h - half
        end
    end)
    return w
end

function LS:PackRoleStats()
    local w = Widget("role_stats")
    local datas = {}
    t_util:Pairs(role_stats, function(prefab, stats)
        t_util:IPairs(stats, function(stat)
            if stat.icon:find("icon_badge_") then
                table.insert(datas, stat)
            end
        end)
    end)
    local col_stat,size_stat = 7, 38
    local space = size_stat + 2
    local pos_x, pos_y = save_data.lright and 20 or 10, -20
    for i, data_stat in ipairs(datas) do
        local stat = w:AddChild(self:AStat(data_stat, size_stat))
        local col, line = i%col_stat, math.ceil(i / col_stat)
        col = col == 0 and col_stat or col
        stat:SetPosition((col - 1) * space + pos_x, (line-1)*-space + pos_y)
    end
    return w
end


function LS:world_season()
    local seasons = {
        {"春天", "spring"},
        {"夏天", "summer"},
        {"秋天", "autumn"},
        {"冬天", "winter"},
    }
    return self:LineTextBtn("季节", t_util:IPairToIPair(seasons, function(s)
        local meta = {chs = s[1], season = s[2]}
        return {
            text = "{chs}",
            hover = "切换到{chs}！",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_setseason", "{season}")', "切换季节为 {chs}", meta),
            meta = meta,
        }
    end))
end

function LS:world_phase()
    local opts = {
        {
            text = "下阶段",
            hover = lmb.."跳到下一个时间阶段！"..rmb.."玩家跟跳！",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_nextphase")', "跳转到下一时间阶段！"),
            right = function()
                local saver = m_util:GetSaver()
                if not saver then return end
                local fb_db = t_util:GetRecur(TheWorld, "net.components.clock.GetDebugString")
                if not fb_db then return end
                local fn_env = c_util:GetFnEnv(fb_db)
                local TIME_PHASE = fn_env._remainingtimeinphase and fn_env._remainingtimeinphase:value() or 0
                f_util:ExRemote('LongUpdate({left})', '玩家跟跳到下一时间阶段', {left = TIME_PHASE})
            end
        }
    }
    t_util:IPairs({1, 2, 5, 10, 20}, function(day)
        local meta = {day = day}
        table.insert(opts, {
            meta = meta,
            text = "{day}天",
            hover = lmb.."跳过 {day}天！"..rmb.."玩家跟跳！",
            left = f_util:FuncConfirmRemote("跳时间", "你确定要跳过 {day} 天吗？（玩家状态不跟随变化）", 'LongUpdate(TUNING.TOTAL_DAY_TIME*{day}, true)', "跳过 {day} 天", meta),
            right = f_util:FuncConfirmRemote("跳时间", "你确定要跳过 {day} 天吗？（玩家状态会跟随变化）", 'LongUpdate(TUNING.TOTAL_DAY_TIME*{day})', "玩家跟跳 {day} 天", meta),
        })
    end)
    return self:LineTextBtn("时间", opts)
end

function LS:world_weather()
    return self:LineTextBtn("气候", {
        {
            text = "雨雪",
            hover = lmb.."降雨或降雪"..rmb.."停止雨雪",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_forceprecipitation", true)', "降落雨雪"),
            right = f_util:FuncExRemote('TheWorld:PushEvent("ms_forceprecipitation", false)', "停止雨雪")
        },{
            text = "闪电",
            hover = "雷公助我！",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_sendlightningstrike", _U_:GetPosition())', "召唤雷电！"),
            tagnot = "cave",
        },{
            text = "潮湿",
            hover = lmb.."世界潮湿度：100%"..rmb.."世界潮湿度：0",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_deltawetness", 1000)', "世界潮湿度：100%"),
            right = f_util:FuncExRemote('TheWorld:PushEvent("ms_deltawetness", -1000)', "世界潮湿度：0"),
        },{
            text = "月雹",
            hover = lmb.."开始降落玻璃雨！"..rmb.."停止降落玻璃雨！",
            left = function()
                if TheWorld and not TheWorld.state.islunarhailing then
                    f_util:ExRemote('TheWorld:PushEvent("ms_startlunarhail")', '月雹从天而降！')
                end
            end,
            right = function()
                if TheWorld and TheWorld.state.islunarhailing then
                    f_util:ExRemote('local w = TheWorld.net and TheWorld.net.components.weather if w then w:LongUpdate(TUNING.LUNARHAIL_EVENT_TIME) end', '月雹已停止从天而降。')
                end
            end,
            tagnot = "cave",
        }
    })
end

function LS:world_star()
    if not TheWorld or TheWorld:HasTag("cave") then return end
    return self:LineTextBtn("星象", {
        {
            text = "月相",
            hover = lmb.."设置今日月相为满月"..rmb.."设置今日月相为新月",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_setmoonphase",{moonphase = "full"})', "设置月相：满月"),
            right = f_util:FuncExRemote('TheWorld:PushEvent("ms_setmoonphase",{moonphase="new",iswaxing=true})', "设置月相：新月"),
        },{
            text = "日食",
            hover = lmb.."设置今日全天为白天"..rmb.."设置今日全天为黑夜",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_setclocksegs",{day=16,dusk=0,night=0})', "设置日食：白天"),
            right = f_util:FuncExRemote('TheWorld:PushEvent("ms_setclocksegs",{day=0,dusk=0,night=16})', "设置日食：黑夜"),
        },{
            text = "陨石",
            hover = "生成一颗陨石！",
            left = f_util:FuncExRemote('local met=SpawnPrefab("shadowmeteor") local pos=_U_:GetPosition() met.Transform:SetPosition(pos.x, pos.y, pos.z)', "召唤陨石！"),
        },{
            text = "月球风暴",
            hover = lmb.."开启月球风暴"..rmb.."关闭月球风暴",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_startthemoonstorms")', "月球风暴：开启"),
            right = f_util:FuncExRemote('TheWorld:PushEvent("ms_stopthemoonstorms")', "月球风暴：结束"),
        },
    })
end

function LS:cave_npc()
    if not TheWorld or not TheWorld:HasTag("cave") then return end
    local data = {
        {id = "calm", chs = "平息"},
        {id = "warn", chs = "警告"},
        {id = "wild", chs = "暴动"},
        {id = "dawn", chs = "过渡"},
    }
    return self:LineTextBtn("远古阶段", t_util:IPairToIPair(data, function(meta)
        return {
            meta = meta,
            text = "{chs}",
            hover = "修改远古暴动阶段为：{chs}",
            left = f_util:FuncExRemote('TheWorld:PushEvent("nightmarephasechanged","{id}")', "远古状态:{chs}", meta)
        }
    end))
end


function LS:server_speed()
    local opts = t_util:IPairToIPair({0.5, 1, 2, 4}, function(speed)
        local meta = {speed = speed}
        return {
            meta = meta,
            text = speed == 1 and "默认" or "{speed}倍",
            hover = speed == 1 and "恢复默认的运行速度！" or "世界运行速度设置为 {speed} 倍！",
            left = function()
                if speed == 1 then
                    f_util:ExRemote('TheSim:SetTimeScale({speed})', "世界运行速度：默认", meta)
                else
                    f_util:ConfirmRemote("加速世界", "确认要将世界运行速度设置为默认的 {speed} 倍吗？", 'TheSim:SetTimeScale({speed})', "世界运行速度调整：{speed}倍", meta)
                end
            end
        }
    end)
    table.insert(opts, {
        text = "自定义",
        hover = "自定义世界运行速度！",
        left = function()
            h_util:CreateWriteWithClose("请输入世界运行速率：", {
                text = "确认",
                cb = function(str)
                    local speed = tonumber(str)
                    if speed and speed > 0 then
                        f_util:ExRemote('TheSim:SetTimeScale({speed})', "自定义世界运行速度：{speed}倍", {speed = speed})
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入一个正数哦。")
                    end
                end
            })
        end
    })
    return self:LineTextBtn("运行速度", opts)
end

function LS:server_rollback()
    local opts = t_util:BuildNumInsert(1, 6, function(num)
        local meta = {num = num}
        return {
            meta = meta,
            text = "[{num}]",
            hover = "回滚{num}次快照",
            left = f_util:FuncConfirmRemote("回滚", "确定要回滚{num}次快照吗？", 'c_rollback({num})', "将回滚{num}次快照...", meta)
        }
    end)
    table.insert(opts, {
        text = "自定义",
        hover = "自定义回滚次数",
        left = function()
            h_util:CreateWriteWithClose("请输入回滚次数：", {
                text = "确认",
                cb = function(str)
                    local num = tonumber(str)
                    if num and num >= 0 and num % 1 == 0 then
                        f_util:ExRemote('c_rollback({num})', "自定义回滚{num}次快照...", {num = num})
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入零或者正整数哦。")
                    end
                end
            })
        end
    })
    return self:LineTextBtn("回滚", opts)
end

function LS:server_common()
    return self:LineTextBtn("服务器", {
        {
            text = "重载游戏",
            hover = lmb.."重新加载世界！"..rmb.."保存并重载游戏！",
            left = f_util:FuncConfirmRemote("重载游戏", "确定要重新加载游戏吗？所有未保存的进度将会丢失。", 'c_reset()', "重载游戏中..."),
            right = f_util:FuncConfirmRemote("保存并重载游戏", "确认要保存并重新加载游戏吗？", "c_save() if TheWorld then TheWorld:DoTaskInTime(5, function() c_reset() end) end", "保存游戏中...5秒后将重载游戏...")
        },{
            text = "生成世界",
            hover = "销毁存档并生成新的世界！",
            left = f_util:FuncConfirmRemote("生成世界", "确定要生成新的世界吗？当前世界的所有存档将被销毁！", 'c_regenerateworld()', "重新生成世界中...")
        },{
            text = "保存游戏",
            hover = "保存游戏进度！",
            left = f_util:FuncExRemote("c_save()", "保存游戏...")
        }
    })
end

function LS:server_advance()
    local opts = {{
        text = "活动修改",
        hover = "将修改服务器的活动",
        left = function()
            local events = t_util:MergeList({{"default", "自动"}, {"none", "无"}}, t_util:PairToIPair(SPECIAL_EVENTS or {}, function(upper, key)
                local name = type(key)=="string" and t_util:GetRecur(STRINGS, "UI.CUSTOMIZATIONSCREEN."..key:upper())
                return name and {key, name}
            end))
            m_util:AddBindShowScreen({
                title = "服务器活动修改",
                id = "server_event_modify",
                data = t_util:IPairToIPair(events, function(data)
                    return {
                        id = data[1],
                        label = data[2],
                        hover = "将服务器活动修改为 "..data[2],
                        type = "box",
                        fn = f_util:FuncConfirmRemote("服务器活动修改", "确定要修改服务器活动为 {chs} 吗？", 'ApplySpecialEvent("{event}")TheWorld.topology.overrides.specialevent="{event}" c_save() if TheWorld then TheWorld:DoTaskInTime(5, function() c_reset() end) end', "服务器活动修改为 {chs}, 五秒后将重新载入世界...", {event = data[1], chs = data[2]}, function()
                                m_util:PopShowScreen()
                            end)
                    }
                end)
            })()
        end
    }}
    if TheWorld then
        if TheWorld:HasTag("cave") then
            table.insert(opts, 1, {
                text = "重置远古",
                hover = "立即刷新所有远古生物",
                left = f_util:FuncConfirmRemote("重置远古", "确定要重置远古吗？暗影灌注…恶灵再次复苏…", 'TheWorld:PushEvent("resetruins")')
            })
        else
            table.insert(opts, 1, {
                text = "移除道路",
                hover = "移除卵石路等原生存在的道路\n用于更美观的建家",
                left  = f_util:FuncConfirmRemote("警告 · 移除道路", "确定要移除道路吗？此操作不可逆！", 'Roads={}c_save()if TheWorld then TheWorld:DoTaskInTime(5, function() c_reset() end) end')
            })
        end
    end
    return self:LineTextBtn("高级", opts)
end

function LS:player_advance()
    local opts = {{
        text = "解锁科技",
        hover = "解锁所有物品配方",
        left = f_util:FuncConfirmRemote("解锁科技", "确定要解锁所有物品配方吗？该操作不可逆！", 'for p in pairs(AllRecipes)do if type(p)=="string" then _P_.components.builder:AddRecipe(p) end end', "解锁所有物品配方")
    }}
    return self:LineTextBtn("高级", opts)
end


function LS:player_telepos()
    local opts = t_util:BuildNumInsert(1, 6, function(num)
        local meta = {num = num}
        return {
            meta = meta,
            text = '[{num}]',
            hover = lmb.."传送至点位[{num}]"..rmb.."保存玩家点位到[{num}]",
            left = function()
                local saver = m_util:GetSaver()
                if not saver then return end
                local pos_line = saver:GetLine("sw_T_mine", true)
                local pos = pos_line[num]
                if not pos then return end
                local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z)
                if x and y and z then
                    f_util:ExRemote("if not _U_.Transform then return end _U_.Transform:SetPosition({x}, {y}, {z})", "传送至当前世界点位[{num}] 坐标：({x}, {y}, {z})", {num = num, x = x, y = y, z = z})
                end
            end,
            right = function()
                local saver = m_util:GetSaver()
                if not saver then return end
                local pos_line = saver:GetLine("sw_T_mine", true)
                if ThePlayer then
                    local pos_player = ThePlayer:GetPosition()
                    local x,y,z = string.format("%.2f", pos_player.x), string.format("%.2f", pos_player.y), string.format("%.2f", pos_player.z)
                    pos_line[num] = {x = x, y = y, z = z}
                    saver:Save()
                    f_util:ExRemote("", "已记录当前世界点位[{num}] 坐标：({x}, {y}, {z})", {x = x, y = y, z = z, num = num})
                end
            end
        }
    end)
    table.insert(opts, {
        text = "地图中心",
        hover = lmb.."传送至地图(0, 0, 0)"..rmb.."自定义坐标",
        left = f_util:FuncExRemote("if not _U_.Transform then return end _U_.Transform:SetPosition(0, 0, 0)", "传送至地图中心"),
        right = function()
            h_util:CreateWriteWithClose("请输入x,y,z坐标,用逗号分隔：", {
                text = "确认",
                cb = function(str)
                    local cleaned = str:gsub("%s+", "")
                    local ns = {}
                    for n in cleaned:gmatch("([^,，、;；]+)") do
                        table.insert(ns, tonumber(n))
                    end
                    local l = #ns
                    if l>1 then
                        f_util:ExRemote("_U_.Transform:SetPosition({x},{y},{z})", "传送至({x},{y},{z})", {x = ns[1], y = l==2 and 0 or ns[2], z = l==2 and ns[2]or ns[3]})
                    else
                        h_util:CreatePopupWithClose("不行的", "至少输入两个数字哦，记得用逗号分隔。")
                    end
                end
            })
        end
    })
    return self:LineTextBtn("位置", opts)
end

function LS:player_speed()
    local code_speed = 'local h=_U_.components.locomotor if h then h:SetExternalSpeedMultiplier(_U_,"c_speedmult",{speed})end'
    local opts = t_util:IPairToIPair({0.5, 1, 2, 4, 6}, function(speed)
        local meta = {speed = speed}
        return {
            meta = meta,
            text = speed == 1 and "正常" or "{speed}倍",
            hover = speed == 1 and "恢复默认玩家的默认移速" or "将玩家移速设置为正常速度的{speed}倍",
            left = f_util:FuncExRemote(code_speed, speed == 1 and "恢复默认移速" or "玩家移动速度：{speed}倍", meta)
        }
    end)
    table.insert(opts, {
        text = "自定义",
        hover = "自定义玩家移动速度！",
        left = function()
            h_util:CreateWriteWithClose("请输入玩家移动速率：", {
                text = "确认",
                cb = function(str)
                    local speed = tonumber(str)
                    if speed then
                        f_util:ExRemote(code_speed, "自定义玩家移速：{speed}倍", {speed = speed})
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入一个数字哦。")
                    end
                end
            })
        end
    })

    return self:LineTextBtn("移速", opts)
end

function LS:player_hunger()
    local code_speed = 'local h,r=_U_.components.hunger,TUNING.WILSON_HUNGER_RATE if h and r then h:SetRate({speed}*r)end'
    local opts = t_util:IPairToIPair({.5, 1, 2, 4}, function(speed)
        local meta = {speed = speed}
        return {
            meta = meta,
            text = speed == 1 and "正常" or "{speed}倍",
            hover = speed == 1 and "恢复默认玩家的饥饿速率" or "将玩家饥饿速率为正常速率的{speed}倍",
            left = f_util:FuncExRemote(code_speed, speed == 1 and "恢复默认饥饿速率" or "玩家饥饿速率：{speed}倍", meta),
        }
    end)
    table.insert(opts, {
        text = "自定义",
        hover = "自定义玩家饥饿速率！",
        left = function()
            h_util:CreateWriteWithClose("请输入玩家饥饿速率：", {
                text = "确认",
                cb = function(str)
                    local speed = tonumber(str)
                    if speed then
                        f_util:ExRemote(code_speed, "自定义玩家饥饿速率：{speed}倍", {speed = speed})
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入一个数字哦。")
                    end
                end
            })
        end
    })

    return self:LineTextBtn("饥饿速率", opts)
end

function LS:player_all()
    return self:LineTextBtn("全体", {
        {
            text = "召集",
            hover = "将召集所有玩家！",
            left = f_util:FuncConfirmRemote("温馨提醒", "确定要召集所有玩家过来吗？这也许不太礼貌！", 'local p=_U_:GetPosition()for _,v in pairs(AllPlayers)do v.Transform:SetPosition(p.x, p.y, p.z)end', "全体召集！")
        },
        {
            text = "死亡",
            hover = "所有玩家死亡！",
            left = f_util:FuncConfirmRemote("温馨提醒", "确定要把所有玩家变成幽灵吗？这也许不太礼貌！", 'for _,v in pairs(AllPlayers)do if not v:HasTag("playerghost")then v:PushEvent("death") v.deathpkname="【远控面板】"end end', "所有玩家死亡")
        },
        {
            text = "复活",
            hover = "所有死亡的玩家复活！",
            left = f_util:FuncExRemote('for _,v in pairs(AllPlayers)do if v:HasTag("playerghost")then v:PushEvent("respawnfromghost")v.rezsource="【远控面板】"end end', "复活所有玩家")
        },
        {
            text = "回复",
            hover = "所有玩家状态回复！",
            left = f_util:FuncExRemote(f_util:CodeFull()..'for _,v in pairs(AllPlayers)do Full(v)end', "回复所有玩家"),
        },
    })
end

function LS:player_single()
    return self:LineTextBtn("单人", {
        {
            text = "回复",
            hover = "回复玩家状态!",
            left = f_util:FuncExRemote(f_util:CodeFull()..'Full(_U_)', "回复玩家状态")
        },
        {
            text = "地图",
            hover = lmb.."显示完整地图"..rmb.."临时清空地图数据",
            left = f_util:FuncConfirmRemote("提示", "你确定要解锁地图吗？\n这需要一定时间，数据将永久保留！", 'local m = _U_.player_classified and _U_.player_classified.MapExplorer if not m then return end local size=TheWorld.Map:GetSize()*4.1 for x=-size,size,35 do for y=-size,size,35 do m:RevealArea(x, 0, y) end end', "显示完整地图"),
            right = function()
                if t_util:GetRecur(TheWorld, "minimap.MiniMap") then
                    TheWorld.minimap.MiniMap:ClearRevealedAreas()
                    f_util:ExRemote("", "临时隐藏地图")
                end 
            end
        },{
            text = "芜猴",
            hover = lmb.."转变为芜猴！"..rmb.."转变为人类！",
            left = function()
                local info = f_util:GetUserInfo()
                local code_wonkey = 'if _U_.prefab=="wonkey"then return end '..f_util:CodePrefab({cursed_monkey_token=10})
                local tip_wonkey = '{name}变成了芜猴！'
                if table.contains(DST_CHARACTERLIST, info and info.prefab) then
                    f_util:ExRemote(code_wonkey, tip_wonkey)
                else
                    f_util:ConfirmRemote("警告", "确定要变身芜猴吗？部分模组角色可能崩溃！", code_wonkey, tip_wonkey)
                end
            end,
            right = f_util:FuncExRemote('local c=_U_.components.cursable if c then c:RemoveCurse("MONKEY",999)end', '{name}摆脱了芜猴的诅咒。')
        },{
            text = "迁移",
            hover = "跨世界传送！",
            left = f_util:FuncExRemote('TheWorld:PushEvent("ms_playerdespawnandmigrate",{player=_U_,worldid=next(Shard_GetConnectedShards())})', "{name} 已被跨世界转送")
        },{
            text = "重选",
            hover = lmb.."重选角色(保留科技)"..rmb.."重选角色(不保留科技)",
            left = f_util.DespawnSave,
            right = f_util.DespawnDrop,
        }
    })
end

function LS:player_unlock()
    return self:LineTextBtn("技能树", {
        {
            text = "获得洞察点",
            hover = "将洞察点增加到最大！",
            left = f_util:FuncExRemote('local com_s=_U_.components.skilltreeupdater if not com_s then return end com_s:AddSkillXP(TheSkillTree:GetMaximumExperiencePoints())', "获得洞察点")
        },
        {
            text = "重置技能树",
            hover = "将撤销点击的技能点\n可能需要点击多次",
            left = f_util:FuncExRemote('local com_s=_U_.components.skilltreeupdater if not com_s then return end local sf=require("prefabs/skilltree_defs").SKILLTREE_DEFS[_U_.prefab]for s in pairs(sf or{})do com_s:DeactivateSkill(s)end', "重置技能树")
        },{
            text = "弹窗修复",
            hover = "如果没有技能树的角色获得了洞察点，可以点击这里修复！",
            left = function()
                if not (ThePlayer and TheSkillTree) then return end
                local p = ThePlayer.prefab
                h_util:CreatePopupWithClose("警告", "你确定要修复 "..e_util:GetPrefabName(p).." 的技能树弹窗吗？\n该功能会清空洞察点，所以务必没有技能树的角色使用！", {{text = h_util.yes, cb = function()
                    TheSkillTree.skillxp[p]=0 
                    TheSkillTree:UpdateSaveState(p)
                    ThePlayer.new_skill_available_popup = nil
                    local t = t_util:GetRecur(ThePlayer, "HUD.controls.skilltree_notification")
                    if t then
                     t:UpdateElements()
                    end
                end}, {text = h_util.no}})
            end
        }
    })
end



function LS:ent_near()
    return self:LineTextBtn("附近", {
        {
            text = "删除",
            hover = lmb.."删除附近实体！"..rmb.."清理全屏实体！",
            left = f_util:FuncExRemote(code_range_delete, "删除范围 {range_delete}", {range_delete = save_data.range_delete or 3}),
            right = f_util:FuncConfirmRemote("警告", "你确定要清理加载范围内的所有实体吗？这是个危险操作！", code_range_delete, "全屏清理！", {range_delete = 64})
        },{
            text = "击杀",
            hover = lmb.."击杀附近生物！"..rmb.."击杀附近玩家！",
            left = f_util:FuncExRemote('local pos=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(pos.x,pos.y,pos.z,{range},{"_combat","_health"},{"player","inlimbo","wall","structure"}))do if v.components and v.components.health then v.components.health:Kill() end end', "击杀半径{range}内的生物", {range = save_data.range_kill or 20}),
            right = f_util:FuncExRemote('local pos=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(pos.x,pos.y,pos.z,{range},{"player"}))do if v~=_U_ and v.components.health then v.components.health:Kill()end end', "击杀半径{range}内的玩家", {range = save_data.range_kill or 20})
        },{
            text = "灭火",
            hover = "熄灭附近火焰！",
            left = f_util:FuncExRemote('local pos=_U_:GetPosition()for _,o in ipairs(TheSim:FindEntities(pos.x,pos.y,pos.z,64))do local b = o.components and o.components.burnable if b then b:Extinguish(true, -1)end end', "熄灭附近所有火焰")
        },{
            text = "修复",
            hover = "修复附近被烧毁的建筑",
            left = f_util:FuncExRemote('local p=_U_:GetPosition()for _,o in ipairs(TheSim:FindEntities(p.x,p.y,p.z,64,{"burnt", "structure"}, {"INLIMBO"}))do local op=o:GetPosition()o:Remove() local n=SpawnPrefab(tostring(o.prefab),tostring(o.skinname),nil,_P_.userid)if n then n.Transform:SetPosition(op:Get())end end', "修复附近被烧毁的建筑")
        },{
            text = "冻结",
            hover = lmb.."冻结附近实体60秒！"..rmb.."冻结附近玩家60秒！",
            left = f_util:FuncExRemote('local p=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(p.x,p.y,p.z,64,nil,{"player"}))do local f=v.components and v.components.freezable if f then f:AddColdness(100,60)end end', "冻结附近实体"),
            right = f_util:FuncExRemote('local p=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(p.x,p.y,p.z,64,{"player"}))do local f=v~=_U_ and v.components and v.components.freezable if f then f:AddColdness(100,60)end end', "冻结附近玩家"),
        },{
            text = "催眠",
            hover = lmb.."催眠附近实体60秒！"..rmb.."催眠附近玩家60秒！",
            left = f_util:FuncExRemote('local p=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(p.x,p.y,p.z,64,{"sleeper"},{"player","playerghost", "FX", "DECOR", "INLIMBO"}))do local c=v.components if c then local i, m if c.rider then i = c.rider:IsRiding() m = c.rider:GetMount() end if m then m:PushEvent("ridersleep", { sleepiness = 10, sleeptime = 60 }) end if c.sleeper then c.sleeper:AddSleepiness(10, 60) elseif c.grogginess then c.grogginess:AddGrogginess(10, 60) else v:PushEvent("knockedout") end local fx = SpawnPrefab(i and "fx_book_sleep_mount" or "fx_book_sleep") fx.Transform:SetPosition(v.Transform:GetWorldPosition())fx.Transform:SetRotation(v.Transform:GetRotation())end end', "催眠附近实体"),
            right = f_util:FuncExRemote('local p=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(p.x,p.y,p.z,64,{"player"},{"playerghost", "FX", "DECOR", "INLIMBO"}))do local c=v~=_U_ and v.components if c then local i, m if c.rider then i = c.rider:IsRiding() m = c.rider:GetMount() end if m then m:PushEvent("ridersleep", { sleepiness = 10, sleeptime = 60 }) end if c.sleeper then c.sleeper:AddSleepiness(10, 60) elseif c.grogginess then c.grogginess:AddGrogginess(10, 60) else v:PushEvent("knockedout") end local fx = SpawnPrefab(i and "fx_book_sleep_mount" or "fx_book_sleep") fx.Transform:SetPosition(v.Transform:GetWorldPosition()) fx.Transform:SetRotation(v.Transform:GetRotation()) end end', "催眠附近玩家"),
        }
    })
end

function LS:ent_plant()
    return self:LineTextBtn("种植", {
        {
            text = "施肥",
            hover = "对附近枯萎的植物进行施肥\n耕地也会补满肥料和水分！",
            left = f_util:FuncExRemote('local pt=_U_:GetPosition() for _,o in ipairs(TheSim:FindEntities(pt.x,pt.y,pt.z,64,nil,{"inlimbo","player"}))do if o.UpdateOverlay then local wx,wy,wz=o.Transform:GetWorldPosition()local tx,ty=TheWorld.Map:GetTileCoordsAtPoint(wx,wy,wz) TheWorld.components.farming_manager:SetTileNutrients(tx, ty, 100, 100, 100)TheWorld.components.farming_manager:AddSoilMoistureAtPoint(wx, wy, wz, TUNING.SOIL_MAX_MOISTURE_VALUE)end local p=o.components and o.components.pickable if p and p:CanBeFertilized() then local f=SpawnPrefab("compostwrap") p:Fertilize(f) if f then f:Remove() end end end', "对附近土壤和农作物施肥"),
        },{
            text = "催熟",
            hover = "催熟附近植物, 农田植株也强制巨大化！",
            left = function()
                local code_str = 'local function Grow(o) local c=o.components if c then if c.witherable and c.witherable:IsWithered() then return end '..
                'local g=c.growable if g then if o:HasTag("farm_plant") and g.stages then o.is_oversized = true return g:SetStage(#g.stages-1) '..
                'elseif g.magicgrowable or((o:HasTag("tree") or o:HasTag("winter_tree")) and not o:HasTag("stump"))then if c.simplemagicgrower then return c.simplemagicgrower:StartGrowing() elseif c.domagicgrowthfn then return g:DoMagicGrowth() else return g:DoGrowth() end end end '..
                'if c.pickable then print(o)if c.pickable:CanBePicked()and c.pickable.caninteractwith then return end if c.pickable:FinishGrowing() then return c.pickable:ConsumeCycles(1) end end '..
                'if c.crop and (c.crop.rate or 0)>0 then return c.crop:DoGrow(1/c.crop.rate,true) end if c.harvestable and c.harvestable:CanBeHarvested() and o:HasTag("mushroom_farm")then if c.harvestable:IsMagicGrowable()then return c.harvestable:DoMagicGrowth() else return c.harvestable:Grow() end end end end '..
                'local pt=_U_:GetPosition() for _,o in ipairs(TheSim:FindEntities(pt.x,pt.y,pt.z,64,nil,{"inlimbo","player"}))do Grow(o)end'
                f_util:ExRemote(code_str, "催熟附近植物")
            end
        },{
            text = "收获",
            hover = "收获附近所有农作物！",
            left = f_util:FuncExRemote('local p=_U_ if p:HasTag("playerghost")then return end local pt=p:GetPosition()for _,o in ipairs(TheSim:FindEntities(pt.x,pt.y,pt.z,64,nil,{"player","flower","trap","mine","NOCLICK","DECOR","FX","cage","donotautopick","INLIMBO"}))do local c=o.components if c then for _,f in ipairs({"pickable","crop","harvestable","stewer","dryer"})do if c[f] then if c[f].Harvest then c[f]:Harvest(p)elseif c[f].Pick then c[f]:Pick(p)end end end end end', "收获附近作物")
        },{
            text = "拾取",
            hover = "拾取附近地上物品！",
            left = f_util:FuncExRemote('local i=_U_.components.inventory if _U_:HasTag("playerghost")or not i then return end local pt=_U_:GetPosition() for _,v in ipairs(TheSim:FindEntities(pt.x,pt.y,pt.z,64,{"_inventoryitem"},{"player","flower","NOCLICK","DECOR","FX","donotautopick","INLIMBO"}))do i:GiveItem(v)end', "拾取附近物品")
        }
    })
end

function LS:ent_beef()
    local datas = {
        {
            chs = "默认",
            tendency = "DEFAULT",
        },{
            chs = "骑行",
            tendency = "RIDER",
        },{
            chs = "战斗",
            tendency = "ORNERY",
        },{
            chs = "宠物",
            tendency = "PUDGY",
        }
    }
    local opts = t_util:IPairToIPair(datas, function(data)
        local meta = {saddle = f_util:fnSmark("saddle_shadow"), tendency = f_util:fnSmark(data.tendency), chs=data.chs}
        return {
            meta = meta,
            text = "{chs}",
            hover = lmb.."生成一头{chs}驯化牛"..rmb.."不装备鞍具",
            left = f_util:FuncExRemote('local b=SpawnPrefab("beefalo") if not b then return end local pt=_U_:GetPosition() local c=b.components local d=c.domesticatable d:DeltaTendency({tendency}, 1) d:DeltaObedience(1) d:DeltaDomestication(1) d:BecomeDomesticated() b:SetTendency() c.hunger:SetPercent(.5) c.rideable:SetSaddle(nil, SpawnPrefab({saddle})) b.Transform:SetPosition(pt.x,pt.y,pt.z) local bb=SpawnPrefab("shadow_beef_bell") if _U_.components.inventory and b then _U_.components.inventory:GiveItem(bb) bb.components.useabletargeteditem:StartUsingItem(b,_U_)end', "生成{chs}驯化牛", meta),
            right = f_util:FuncExRemote('local b=SpawnPrefab("beefalo") if not b then return end local pt=_U_:GetPosition() local c=b.components local d=c.domesticatable d:DeltaTendency({tendency}, 1) d:DeltaObedience(1) d:DeltaDomestication(1) d:BecomeDomesticated() b:SetTendency() c.hunger:SetPercent(.5) b.Transform:SetPosition(pt.x,pt.y,pt.z)', "生成{chs}驯化牛(无鞍具)", meta)
        }
    end)
    return self:LineTextBtn(e_util:GetPrefabName("beefalo"), opts)
end

function LS:ent_all()
    return self:LineTextBtn("生物", {
        {
            text = "消除仇恨",
            hover = "消除附近实体们仇恨！",
            left = f_util:FuncExRemote(f_util:CodeEnts('local c=o.components if c then if c.combat then c.combat:SetTarget(nil)end end'), "消除附近仇恨")
        },{
            text = "状态回复",
            hover = "回复附近实体们生命和饥饿！(非玩家)",
            left = f_util:FuncExRemote(f_util:CodeEnts('local h=o.components and o.components.health if h then h:SetPercent(1)end local u=o.components and o.components.hunger if u then u:SetPercent(1)end'), "回复附近生物")
        },{
            text = "控制移动",
            hover = lmb.."附近生物禁止移动！"..rmb.."附近生物允许移动！",
            left = f_util:FuncExRemote(f_util:CodeEnts('local l=o.components and o.components.locomotor if not l then return end l:SetExternalSpeedMultiplier(o,"c_speedmult",{speed})'), "禁止附近生物移动",{speed = 0}),
            right = f_util:FuncExRemote(f_util:CodeEnts('local l=o.components and o.components.locomotor if not l then return end l:SetExternalSpeedMultiplier(o,"c_speedmult",{speed})'), "允许附近生物移动",{speed = 1}),
        }
    })
end

function LS:ent_spawn()
    return self:LineTextBtn("生成", {
        {
            text = "攻速人偶",
            hover = "生成一个测试攻速的人偶！\n(重启游戏后失效)",
            left = f_util:FuncExRemote('local r = SpawnPrefab("sewing_mannequin") r.Transform:SetPosition(_U_:GetPosition():Get()) r:AddComponent("health") r.components.health:SetMaxHealth(TUNING.TOADSTOOL_DARK_HEALTH) r:AddComponent("combat") r._lasttime = 0 r._sumtime = 0 r._sumamout = 0 r:ListenForEvent("healthdelta", function(r, d) local function round(num) return tostring(math.floor(num * 1000 + 0.5) / 1000) end local am = -d.amount local str = "单次伤害：" .. round(am) local now = GetTime() local pt = now - r._lasttime str = str .. string.char(10) .. "攻击间隔：" .. round(pt) str = str .. string.char(10) .. "实时攻速：" .. round(1 / pt) if pt > 3 or r._sumtime == 0 then r._sumtime = now r._sumamout = am str = str .. string.char(10) .. "开始计时（冷却3s）" else r._sumamout = r._sumamout + am str = str .. string.char(10) .. "每秒伤害：" .. round((r._sumamout - am) / (now - r._sumtime)) end r.components.talker:Say(str) r._lasttime = now end)', "生成攻速人偶")
        },{
            text = "链接虫洞",
            hover = "生成一个虫洞，并自动与尚未相连的虫洞相连！",
            left = f_util:FuncExRemote('local x, y, z = _U_.Transform:GetWorldPosition() local ents = TheSim:FindEntities(x, y, z, 9001) local old_worm for _, v in pairs(ents) do if v.prefab == "wormhole" then if v.components and v.components.teleporter and v.components.teleporter.targetTeleporter == nil then old_worm = v end end end local new_worm = SpawnPrefab("wormhole") new_worm.Transform:SetPosition(x, y, z) if old_worm then old_worm.components.teleporter.targetTeleporter = new_worm new_worm.components.teleporter.targetTeleporter = old_worm end', "生成链接虫洞")
        }
    })
end


function LS:test_boss()
    local data_list = {
        {
            text = "梦魇疯猪",
            hover = "生成梦魇疯猪\n(带锁链)",
            left = f_util:FuncExRemote('require("debugcommands")d_daywalker(true)', "生成梦魇疯猪(带锁链)")
        },{
            text = "天体英雄",
            hover = "生成召唤天体英雄所需",
            left = f_util:FuncExRemote([[
	local offset = 7
	local pos = ConsoleWorldPosition()
	local altar 
    
    altar = SpawnPrefab("moon_altar")
	altar.Transform:SetPosition(pos.x, 0, pos.z - offset)
	altar:set_stage_fn(2)
    
	SpawnPrefab("moon_altar_idol").Transform:SetPosition(pos.x, 0, pos.z - offset - 2)

	altar = SpawnPrefab("moon_altar_astral")
	altar.Transform:SetPosition(pos.x - offset, 0, pos.z + offset / 3)
	altar:set_stage_fn(2)

	altar = SpawnPrefab("moon_altar_cosmic")
	altar.Transform:SetPosition(pos.x + offset, 0, pos.z + offset / 3)

    c_give("wagpunk_bits", 4)
    c_give("moonstorm_spark", 10)
    c_give("moonglass_charged", 30)
    c_give("moonstorm_static_item", 1)
    c_give("moonrockseed", 1)
    ]], "生成召唤天体英雄所需")
        }
    }
    if TheWorld and TheWorld:HasTag("forest") then
        t_util:Add(data_list, {
            text = "拾荒刷新",
            hover = "立即刷新拾荒疯猪\n(限定森林)",
            left = f_util:FuncExRemote([[
    local fws = TheWorld and TheWorld.components.forestdaywalkerspawner
    local sds = TheWorld and TheWorld.shard and TheWorld.shard.components.shard_daywalkerspawner
    if fws and sds then
        sds:SetLocation("forestjunkpile")
        fws.days_to_spawn = 0
    end
    ]], "立即刷新拾荒疯猪")
        }, true)
    end
    return self:LineTextBtn("巨兽", data_list)
end

function LS:test_show()
    return self:PackLines(self:LineTextBtn("提示", {{
        text = "该页面用于开发者调试",
        hover = "尚未获得授权",
    }}))
end

function LS:test_treerock()
    return self:LineTextBtn("巨石树", {
        {
            text = "阵列1",
            hover = "生成巨石树阵列1",
            left = function()
                if not ThePlayer then return end
                local cx, _, cz = TheWorld.Map:GetTileCenterPoint(ThePlayer.Transform:GetWorldPosition())
                if cx then
                    f_util:ExRemote('local r={count}*4 for x={cx}-r,{cx}+r,4 do for z={cz}-r,{cz}+r,4 do SpawnPrefab("tree_rock1").Transform:SetPosition(x, 0, z) end end', "生成巨石树阵列1", {cx = cx, cz = cz, count = 3})
                end
            end
        },
        {
            text = "阵列2",
            hover = "生成巨石树阵列2",
            left = function()
                if not ThePlayer then return end
                local cx, _, cz = TheWorld.Map:GetTileCenterPoint(ThePlayer.Transform:GetWorldPosition())
                if cx then
                    f_util:ExRemote('local r={count}*4 for x={cx}-r,{cx}+r,4 do for z={cz}-r,{cz}+r,4 do SpawnPrefab("tree_rock").Transform:SetPosition(x, 0, z) end end', "生成巨石树阵列2", {cx = cx, cz = cz, count = 3})
                end
            end
        },
    })
end

function LS:test_beebox()
    return self:LineTextBtn("面板1", {
        {
            text = "蜂箱",
            hover = "生成蜂箱阵列",
            left = function()
                f_util:ExRemote('local function G(p, r, c) local ps = {} local angleStep = 2 * math.pi / c for i = 0, c - 1 do local angle = i * angleStep table.insert(ps, Vector3(p.x + r * math.cos(angle), 0, p.z + r * math.sin(angle))) end return ps end local pt=_P_:GetPosition() for _,p in ipairs(G(pt, {range}, {count}))do local b=SpawnPrefab("beebox") b.Transform:SetPosition(p.x, 0, p.z) b.components.harvestable.produce=5 b.components.harvestable:Grow() end f=SpawnPrefab("firesuppressor")f.Transform:SetPosition(pt.x, 0, pt.z)', "生成蜂箱阵列", {range = 10, count = 15})
            end
        },
        {
            text = "池塘",
            hover = "生成池塘阵列",
            left = function()
                f_util:ExRemote('local function G(p, r, c) local ps = {} local angleStep = 2 * math.pi / c for i = 0, c - 1 do local angle = i * angleStep table.insert(ps, Vector3(p.x + r * math.cos(angle), 0, p.z + r * math.sin(angle))) end return ps end local pt=_P_:GetPosition() for _,p in ipairs(G(pt, {range}, {count}))do local b=SpawnPrefab("pond_cave") b.Transform:SetPosition(p.x, 0, p.z) end', "生成池塘阵列", {range = 15, count = 10})
            end
        },
    })
end

return LS