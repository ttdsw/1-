if m_util:IsServer() and not m_util:IsLava() then
    return
end
local r_data = require "data/rangetable"
local save_id = "range_key"
local default_data = {
    highlight = true,
    color_combat = "红色",
    color_ori = "蓝色",
    color_track = "紫色",
    autoshow = true,
    search_seed = false,
    color_player = "蓝色",
    color_hover = "蓝色",
    color_click = "魔力紫",
    color_placer = "黄色",
    time_click = 30
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local c_data = {
    range_attack = m_util:IsTurnOn("range_attack"),
    range_search = m_util:IsTurnOn("range_search"),
    animal_track = m_util:IsTurnOn("animal_track"),
    range_player = m_util:IsTurnOn("range_player"),
    range_hover = m_util:IsTurnOn("range_hover"),
    range_click = m_util:IsTurnOn("range_click"),
    range_placer = m_util:IsTurnOn("range_placer")
}

local function apply(prefab, color, range, always, add, quick, callback)
    prefab = prefab:lower()
    add = add or 0
    range = range + add
    local rotary_name = "atkr_%s" .. range
    local flushTime = quick and 0.1 or 1
    AddPrefabPostInit(prefab, function(inst)
        inst:DoPeriodicTask(flushTime, function()
            local rotary = inst[rotary_name]
            local tcolor = color or save_data.color_ori
            if not rotary then
                inst[rotary_name] = inst:SpawnChild("hrange"):SetVisable(false):SetFixedRadius(range):SetColor(tcolor)
                if prefab == "tallbird" then
                    inst[rotary_name]:AddTag(prefab) 
                end
            else
                if callback then
                    local trans = e_util:IsValid(inst)
                    if trans then
                        callback(rotary, inst, trans:GetScale())
                    end
                end
                if not c_data.range_attack then 
                    e_util:SetHighlight(inst, false)
                    rotary:SetVisable(false)
                    return
                end
                if e_util:GetCombatTarget(inst) == ThePlayer then
                    e_util:SetHighlight(inst, save_data.highlight)
                    rotary:SetVisable(true):SetColor(save_data.color_combat)
                elseif always or not save_data.autoshow then
                    rotary:SetVisable(true):SetColor(tcolor)
                else
                    e_util:SetHighlight(inst, false)
                    local dist = e_util:GetDist(inst)
                    rotary:SetVisable(not (dist and dist > 3 * range) and not e_util:GetLeaderTarget(inst)):SetColor(
                        tcolor)
                end
            end
        end)
    end)
end
local function LoopAdd(datas, add)
    t_util:IPairs(datas, function(data)
        t_util:IPairs(data.prefabs, function(prefab)
            t_util:Pairs(data.rotary, function(key, value)
                local range, color, fn

                local tp_key, tp_value = type(key), type(value)
                if tp_key == "number" and tp_value == "string" then
                    range, color = key, value
                elseif tp_key == "number" and tp_value == "function" then
                    range, fn = key, value
                elseif tp_value == "number" then
                    range = value
                end
                if range then
                    apply(prefab, color, range, data.always, add, data.quick, fn)
                end
            end)
        end)
    end)
end
LoopAdd(r_data.attack_range, 0.5)
LoopAdd(r_data.target_range, 0)


local core_tasks = {}
local core
i_util:AddWorldActivatedFunc(function()
    core = e_util:SpawnNull()
    core.entity:AddTransform()
    core.prefab = "huxinull"
    core:DoPeriodicTask(FRAMES, function(inst)
        if not c_data.range_search then
            inst:Hide()
        else
            inst:Show()
            local pt = e_util:IsValid(ThePlayer)
            if pt then
                inst.Transform:SetPosition(pt:GetWorldPosition())
            end
            t_util:Pairs(core_tasks, function(task, arrow)
                if e_util:IsValid(task) then
                    local visable
                    if arrow == true then
                        arrow = core:SpawnChild("harrow"):SetColor(r_data.track_range[task.prefab])
                        core_tasks[task] = arrow
                    else
                        local dist = e_util:GetDist(task)
                        if dist then
                            if not task:HasTag("inlimbo") and dist < 80 and dist > 4 then
                                visable = true
                                arrow:Link(core, task)
                            end
                        end
                        if not save_data.search_seed and task.prefab == "seeds" then
                            visable = false
                        end
                    end
                    if visable then
                        arrow:Show()
                    else
                        arrow:Hide()
                    end
                    e_util:SetHighlight(task, save_data.highlight and visable)
                else
                    if arrow ~= true then
                        arrow:Remove()
                        arrow = nil
                    end
                    core_tasks[task] = nil
                end
            end)
        end
    end)
end)
t_util:Pairs(r_data.track_range, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(1, function()
            core_tasks[inst] = true
        end)
    end)
end)


AddPrefabPostInit("animal_track", function(inst)
    local next_thing
    inst:DoPeriodicTask(0.5, function()
        if not c_data.animal_track or not e_util:IsAnim("idle", inst) or not e_util:IsValid(inst) then
            return
        end
        local x, y, z = inst.entity:LocalToWorldSpace(0, 0, -40)
        next_thing = next_thing or e_util:FindEnt({
            x = x,
            y = y,
            z = z
        }, nil, 10, nil, nil, nil, nil, function(e)
            return e:HasOneOfTags({"dirtpile", "_health"})
        end)
        if e_util:IsValid(next_thing) then
            SpawnPrefab("harrow"):SetColor(save_data.color_track):GoTo(inst, next_thing)
        end
    end)
end)


i_util:AddPlayerActivatedFunc(function(player, world, pusher)
    local hrange = player:SpawnChild("hrange"):SetVisable(false)
    local function ShowRange(range)
        hrange:SetFixedRadius(range):SetColor(save_data.color_player):SetVisable(true)
    end
    local function RefreshRod(equip)
        if not c_data.range_player then
            return
        end
        local rod = t_util:GetRecur(equip, "replica.oceanfishingrod")
        if rod then
            ShowRange(rod:GetMaxCastDist())
        end
    end
    pusher:RegEquip(function(slot, equip)
        if not c_data.range_player then
            return
        end
        if slot == "hands" then
            local range = p_util:GetAttackRange(equip)
            if range and range > 4 then
                ShowRange(range + 0.5)
            else
                local rod = t_util:GetRecur(equip, "replica.oceanfishingrod")
                if rod then
                    e_util:SetBindEvent(equip, "itemget", RefreshRod)
                    e_util:SetBindEvent(equip, "itemlose", RefreshRod)
                    RefreshRod(equip)
                end
            end
        end
    end)
    pusher:RegUnequip(function(slot, equip)
        if slot == "hands" then
            hrange:SetVisable(false)
        end
    end)
end)


local hover_range
local function RemoveHoverRange()
    if e_util:IsValid(hover_range) then
        hover_range:Remove()
    end
    hover_range = nil
end
i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    local item = item_inv or item_world
    local parent = item_inv and player or item_world
    if not item or not parent then
        return
    end
    local range = item.prefab and r_data.hover_range[item.prefab]
    if range and not hover_range and c_data.range_hover then
        hover_range = parent:SpawnChild("hrange"):SetFixedRadius(range):SetColor(save_data.color_hover)
        return nil, RemoveHoverRange
    end
end)


i_util:AddLeftClickFunc(function(pc, player, down, act_left, ent_mouse)
    if down then
        return
    end
    if not c_data.range_click then
        return
    end
    local range = ent_mouse and ent_mouse.prefab and r_data.click_range[ent_mouse.prefab]
    if not range or p_util:GetActiveItem() then
        return
    end
    local function add_hrange(num)
        if type(num) ~= "number" then
            return
        end
        local circle = ent_mouse:SpawnChild("hrange"):SetFixedRadius(num):SetColor(save_data.color_click)
        circle:DoTaskInTime(save_data.time_click, circle.Remove)
    end
    if type(range) == "table" then
        t_util:IPairs(range, add_hrange)
    else
        add_hrange(range)
        if ent_mouse.prefab == "eyeturret" and m_util:IsHuxi() then
            local junk = e_util:FindEnt(ent_mouse, "junk_pile_big")
            if junk then
                local length = e_util:GetDist(ent_mouse, junk)
                if length then
                    local str = string.format("%.2f，推荐16.8~22.8", length)
                    u_util:Say("距离垃圾", str, nil, nil, true)
                end
            end
        end
    end
end)


t_util:Pairs(r_data.placer_range, function(prefab, range)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0.1, function(inst)
            if c_data.range_placer then
                inst:SpawnChild("hrange"):SetFixedRadius(range):SetColor(save_data.color_placer)
            end
        end)
    end)
end)

local color_data = require("data/valuetable").WRGB_datatable
local screen_data = {{
    id = "reset",
    label = "重置设置",
    fn = function(_, a, datas)
        t_util:IPairs(datas, function(data)
            local ui = data.id
            local sw = a[ui] and a[ui].switch
            if sw and ui ~= "reset" then
                sw(data.reset)
            end
        end)
    end,
    hover = "点击一键还原默认设置\n【请勿连续点击!】",
    default = true
}, {
    id = "range_attack",
    label = "攻击范围",
    fn = function(state)
        c_data.range_attack = m_util:SaveModOneConfig("range_attack", state)
    end,
    hover = "是否显示攻击范围？\n 你的选择会写入模组设置！",
    default = function()
        return c_data.range_attack
    end,
    reset = true
}, {
    id = "autoshow",
    label = "贴贴显示",
    fn = fn_save("autoshow"),
    hover = "【攻击范围附属功能】\n 在玩家附近才显示范围（美观+节省内存）",
    default = fn_get,
    reset = default_data.autoshow
}, {
    id = "highlight",
    label = "敌对高亮",
    fn = fn_save("highlight"),
    hover = "【攻击范围附属功能】\n对玩家有仇恨的生物显示高亮",
    default = fn_get,
    reset = default_data.highlight
}, {
    id = "color_ori",
    label = "范围颜色:",
    type = "radio",
    fn = fn_save("color_ori"),
    hover = "【攻击范围附属功能】\n生物没有仇恨时攻击范围的颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_ori
}, {
    id = "color_combat",
    label = "敌对颜色:",
    type = "radio",
    fn = fn_save("color_combat"),
    hover = "【攻击范围附属功能】\n敌对生物攻击范围的颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_combat
}, {
    id = "animal_track",
    label = "足迹指引",
    fn = function(state)
        c_data.animal_track = m_util:SaveModOneConfig("animal_track", state)
    end,
    hover = "可疑的脚印会有游动的箭头提示狩猎方向\n 你的选择会写入模组设置！",
    default = function()
        return c_data.animal_track
    end,
    reset = true
}, {
    id = "color_track",
    label = "足迹颜色:",
    type = "radio",
    fn = fn_save("color_track"),
    hover = "【足迹指引附属功能】\n敌对生物攻击范围的颜色",
    default = function()
        return save_data.color_track
    end,
    data = color_data,
    reset = default_data.color_track
}, {
    id = "range_search",
    label = "宝物指示器",
    fn = function(state)
        c_data.range_search = m_util:SaveModOneConfig("range_search", state)
    end,
    hover = "对各种宝石或别的“宝物”增加一个脚下的箭头\n 你的选择会写入模组设置！",
    default = function()
        return c_data.range_search
    end,
    reset = true
}, {
    id = "search_seed",
    label = "种子指示器",
    fn = fn_save("search_seed"),
    hover = "【宝物指示器附属功能】\n 是否额外提示种子的位置？",
    default = fn_get,
    reset = default_data.search_seed
}, {
    id = "range_player",
    label = "远程范围",
    hover = "玩家手持远程武器或者海钓竿时显示对应范围？",
    fn = function(state)
        c_data.range_player = m_util:SaveModOneConfig("range_player", state)
    end,
    default = function()
        return c_data.range_player
    end,
    reset = true
}, {
    id = "color_player",
    label = "范围颜色:",
    type = "radio",
    fn = fn_save("color_player"),
    hover = "【远程范围附属功能】\n远程武器范围的颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_player
}, {
    id = "range_hover",
    label = "悬浮范围",
    hover = "鼠标移动到书籍、排箫等部分实体上显示范围",
    fn = function(state)
        c_data.range_hover = m_util:SaveModOneConfig("range_hover", state)
    end,
    default = function()
        return c_data.range_hover
    end,
    reset = true
}, {
    id = "color_hover",
    label = "范围颜色:",
    type = "radio",
    fn = fn_save("color_hover"),
    hover = "【悬浮范围附属功能】\n鼠标移动到火药、书籍等部分实体上的范围颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_hover
}, {
    id = "range_placer",
    label = "放置范围",
    hover = "放置避雷针、眼球炮台等建筑时是否显示范围",
    fn = function(state)
        c_data.range_placer = m_util:SaveModOneConfig("range_placer", state)
    end,
    default = function()
        return c_data.range_placer
    end,
    reset = true
}, {
    id = "color_placer",
    label = "范围颜色:",
    type = "radio",
    fn = fn_save("color_placer"),
    hover = "【放置范围附属功能】\n放置避雷针、眼球炮台等建筑时的范围颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_placer
}, {
    id = "range_click",
    label = "点击范围",
    hover = "点击灭火器，避雷针等实体是否显示范围",
    fn = function(state)
        c_data.range_click = m_util:SaveModOneConfig("range_click", state)
    end,
    default = function()
        return c_data.range_click
    end,
    reset = true
}, {
    id = "color_click",
    label = "范围颜色:",
    type = "radio",
    fn = fn_save("color_click"),
    hover = "【点击范围附属功能】\n点击灭火器，避雷针等部分实体上的范围颜色",
    default = fn_get,
    data = color_data,
    reset = default_data.color_click
}, {
    id = "time_click",
    label = "延迟时间:",
    type = "radio",
    fn = fn_save("time_click"),
    hover = "【点击范围附属功能】\n点击范围存在的时间, 超过这个时间自动关闭",
    default = fn_get,
    reset = default_data.time_click,
    data = t_util:BuildNumInsert(5, 120, 5, function(i)
        return {
            data = i,
            description = i .. "秒"
        }
    end)
}}

m_util:AddBindShowScreen("range_board", "范围追踪", "alterguardianhat_lastprism", "点击打开范围相关设置",
    {
        title = "超级好用的范围追踪",
        id = save_id,
        data = screen_data,

        icon = {{
            id = "add",
            prefab = "mods",
            hover = "自定义各种范围",
            fn = function()
                h_util:CreatePopupWithClose(nil, "尚未有人定制此功能...")
            end
        }}
    }, nil, 9997)
