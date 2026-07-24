
local lmb, rmb = STRINGS.LMB, "\n"..STRINGS.RMB
local f_util = require "util/fn_hxcb"
local code_ghost = f_util:CodeGhost()
local code_revive = 'if _U_:HasTag("playerghost") then _U_:PushEvent("respawnfromghost") _U_.rezsource = "【远控面板】" end '
local code_cancel = 'if _U_.task_supergod then _U_.task_supergod:Cancel() _U_.task_supergod = nil end '
local code_health = 'local h=_U_.components.health if not h then return end '
local t_util = require "util/tableutil"

local hxcb_stats = {
    {
        icon = "icon_health",
        hover = subfmt(lmb .. '{chs}：100%' .. rmb .. '{chs}：1', {chs = STRINGS.UI.COOKBOOK.SORT_HEALTH}),
        left = function()
            local code_str = code_health..'h:SetPercent(1)h:ForceUpdateHUD(true)'
            f_util:ExRemote(code_revive..code_str, STRINGS.UI.COOKBOOK.SORT_HEALTH.."：100%")
        end,
        right = function()
            local code_str = code_health..'h:SetVal(1)h:ForceUpdateHUD(true)'
            f_util:ExRemote(code_revive..code_str, STRINGS.UI.COOKBOOK.SORT_HEALTH.."：1")
        end
    },
    {
        icon = "icon_sanity",
        hover = subfmt(lmb .. '{chs}：100%' .. rmb .. '{chs}：0', {chs = STRINGS.UI.COOKBOOK.SORT_SANITY}),
        left = function()
            local code_str = 'local h = _U_.components.sanity if h then h:SetPercent(1) end'
            f_util:ExRemote(code_ghost..code_str, STRINGS.UI.COOKBOOK.SORT_SANITY.."：100%")
        end,
        right = function()
            local code_str = 'local h = _U_.components.sanity if h then h:SetPercent(0) end'
            f_util:ExRemote(code_ghost..code_str, STRINGS.UI.COOKBOOK.SORT_SANITY.."：0")
        end
    },
    {
        icon = "icon_hunger",
        hover = subfmt(lmb .. '{chs}：100%' .. rmb .. '{chs}：0', {chs = STRINGS.UI.COOKBOOK.SORT_HUNGER}),
        left = function()
            local code_str = 'local h = _U_.components.hunger if h then h:SetPercent(1) end'
            f_util:ExRemote(code_ghost..code_str, STRINGS.UI.COOKBOOK.SORT_HUNGER.."：100%")
        end,
        right = function()
            local code_str = 'local h = _U_.components.hunger if h then h:SetPercent(0) end'
            f_util:ExRemote(code_ghost..code_str, STRINGS.UI.COOKBOOK.SORT_HUNGER.."：0")
        end
    },
    {
        icon = "icon_wetness",
        hover = subfmt(lmb .. '{chs}：0' .. rmb .. '{chs}：100%', {chs = "潮湿度"}),
        left = function()
            local code_str = 'local h = _U_.components.moisture if h then h:SetPercent(0) end'
            f_util:ExRemote(code_ghost..code_str, "潮湿度：0")
        end,
        right = function()
            local code_str = 'local h = _U_.components.moisture if h then h:SetPercent(1) end'
            f_util:ExRemote(code_ghost..code_str, "潮湿度：100%")
        end,
    },
    {
        icon = "icon_heat",
        hover = subfmt(lmb .. '{chs}：25°' .. rmb .. '{chs}: 世界温度', {chs = "体温"}),
        left = function()
            local code_str = 'local h = _U_.components.temperature if h then h:SetTemperature(25) end'
            f_util:ExRemote(code_ghost..code_str, "体温：25°")
        end,
        right = function()
            local temperature = t_util:GetRecur(TheWorld, "state.temperature")
            if type(temperature) ~= "number" then return end
            temperature = string.format("%.2f", temperature)
            local code_str = 'local h = _U_.components.temperature if h then h:SetTemperature({temperature}) end'
            f_util:ExRemote(code_ghost..code_str, "体温：{temperature}° (世界温度)", {temperature = temperature})
        end,
    },
    {
        icon = "icon_badge_penalty",
        hover = lmb .. '生命上限 +25%' .. rmb .. '生命上限 -25%',
        left = function()
            local code_str = code_health..'h:SetPenalty(h.penalty - 0.25) h:ForceUpdateHUD(true)'
            f_util:ExRemote(code_ghost..code_str, '生命上限 +25%')
        end,
        right = function()
            local code_str = code_health..'h:SetPenalty(h.penalty + 0.25) h:ForceUpdateHUD(true)'
            f_util:ExRemote(code_ghost..code_str, '生命上限 -25%')
        end
    },
    {
        icon = "icon_stack",
        hover = lmb .. '清空物品栏' .. rmb .. '清空背包',
        left = function()
            local code_str = 'local h = _U_.components.inventory if h then h:ForEachItemSlot(function(item)h:RemoveItem(item, true)item:Remove()end) end'
            f_util:ConfirmRemote("清空物品栏", "你确定要移除掉玩家 物品栏内 所有物品吗？", code_str, "清空物品栏")
        end,
        right = function()
            local code_str = 'local h = _U_.components.inventory if h then h:ForEachEquipment(function(equip)if equip and equip:HasTag("backpack")then local e = equip.components.container if e then e:RemoveAllItems()end end return end)end'
            f_util:ConfirmRemote("清空背包", "你确定要移除掉玩家 背包内 所有物品吗？", code_str, "清空背包")
        end
    },
    {
        icon = "icon_badge_god",
        hover = lmb .. '超级上帝模式' .. rmb .. '上帝模式',
        left = f_util.Fn_SuperGodMode,
        right = function()
            local l = f_util.load_data
            l.godmode = not l.godmode
            l.supergod = nil
            local tip_str = l.godmode and '上帝模式：开启' or '上帝模式：关闭'
            local code_str = code_health..'h:SetInvincible({godmode})'
            f_util:ExRemote(code_revive..code_cancel..code_str, tip_str, {godmode = l.godmode})
        end,
    },
    {
        icon = "icon_badge_craft",
        hover = lmb .. '创造模式',
        left = f_util.Fn_CraftMode,
        
        
        
        
    },
    {
        icon = "icon_badge_minhel",
        hover = lmb .. '生命下限锁定：1'..rmb .. '回复玩家状态',
        left = f_util.Fn_HealthyLock,
        right = function()
            f_util:ExRemote(f_util:CodeFull()..'Full(_U_)', "回复玩家状态")
        end
    },
    {
        icon = "icon_damage",
        hover = lmb .. '必杀模式' .. rmb .. '基础三件套',
        left = function()
            local l = f_util.load_data
            l.killmode = not l.killmode
            local tip_str = l.killmode and "一击必杀：启动" or "一击必杀：关闭"
            local code_str = "local c=_U_.components.combat if not c then return end c.__CalcDamage=c.__CalcDamage or c.CalcDamage c.CalcDamage="
            code_str = code_str .. (l.killmode and "function()return 9999999999 end" or "c.__CalcDamage")
            f_util:ExRemote(code_ghost..code_str, tip_str)
        end,
        right = function()
            local code_str, names = f_util:CodePrefab({"armorwood", "hambat", "footballhat"})
            f_util:ConfirmRemote("提示", "将获得如下物品：\n"..names, code_str, "获得基础三件套")
        end
    },
    {
        icon = "icon_badge_ghost",
        hover = lmb .. '隐身模式',  
        left = function()
            local l = f_util.load_data
            l.hidemode = not l.hidemode
            local tip_str = l.hidemode and "隐身模式：启动" or "隐身模式：关闭"
            local code_str = l.hidemode and 'if not _U_:HasTag("notarget")then _U_:AddTag("notarget")end '..f_util:CodeEnts('local c=o.components if c then if c.combat and c.combat.target==_U_ then c.combat:SetTarget(nil)end end') or 'if _U_:HasTag("notarget")then _U_:RemoveTag("notarget")end'
            f_util:ExRemote(code_ghost..code_str, tip_str)
        end
    },
    {
        icon = "icon_badge_flot",
        hover = lmb .. '踏水模式',
        left = function()
            local l = f_util.load_data
            l.watermode = not l.watermode
            local tip_str = l.watermode and "踏水模式：启动" or "踏水模式：关闭"
            local code_str = "local d = _U_.Physics and _U_.Transform and _U_.components.drownable if not d then return end local c = COLLISION "
            local code_str = code_str..(l.watermode 
            and "d.enabled=false _U_.Physics:SetCollisionMask(c.GROUND,c.OBSTACLES,c.SMALLOBSTACLES,c.CHARACTERS,c.GIANTS)"
            or "d.enabled=true _U_.Physics:SetCollisionMask(c.WORLD,c.OBSTACLES,c.SMALLOBSTACLES,c.CHARACTERS,c.GIANTS)" )
            .." _U_.Physics:Teleport(_U_.Transform:GetWorldPosition())"
            f_util:ExRemote(code_ghost..code_str, tip_str)
        end,
    },
    {
        icon = "icon_badge_skull",
        hover = lmb .. '杀死' .. rmb .. '复活',
        left = function()
            local code_str = 'if _U_:HasTag("playerghost") then return end _U_:PushEvent("death") _U_.deathpkname = "【远控面板】"'
            f_util:ConfirmRemote("提示", "确定要杀死 {name} 吗？", code_str, "杀死【{name}】")
        end,
        right = f_util:FuncExRemote(code_revive, "复活【{name}】")
    },
}

return hxcb_stats