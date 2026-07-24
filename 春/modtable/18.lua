if m_util:IsServer() then
    return
end
local save_id = "sw_wagstaff"
local default_data = {
    tool_tip = true,
    textsize = 35,
    color_need = '鲜肉色',
    color_ori = '白色',
    bird_warn = 12,
    range_pick = 30,
    range_catch = 30,
    sw_f = true,
    sw_g = true,
    sw_p = true,
    sw_m = true,
    sw_n = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function Say(who, what)
    u_util:Say(who, what, nil, nil, true)
end
local string_task = "静电任务"

local prefabs = {"wagstaff_tool_1", "wagstaff_tool_2", "wagstaff_tool_3", "wagstaff_tool_4", "wagstaff_tool_5"}
local needprefab, done
local function getName(i)
    return t_util:GetRecur(STRINGS, "NAMES.WAGSTAFF_TOOL_" .. i)
end
for i, prefab in ipairs(prefabs) do
    AddPrefabPostInit(prefab, function(inst)
        inst:DoPeriodicTask(.5, function(inst)
            local label = inst._hx_label
            if label then
                if save_data.tool_tip then
                    if prefab == needprefab then
                        label:SetSize(save_data.textsize + 5):SetColor(save_data.color_need):SetText(getName(i) or "")
                    else
                        label:SetSize(save_data.textsize):SetColor(save_data.color_ori):SetText(getName(i) or "")
                    end
                else
                    label:SetText("")
                end
            else
                local name = getName(i)
                if name then
                    STRINGS.NAMES["WAGSTAFF_TOOL_" .. i .. "_LAYMAN"] = name
                    h_util:CreateLabel(inst, save_data.tool_tip and name or "", nil, nil, save_data.textsize)
                end
            end
        end)
    end)
end
AddPrefabPostInit("wagstaff_npc", function(inst)
    inst:DoTaskInTime(0.25, function(inst)
        needprefab = nil
        e_util:Hook_Say(inst, function(str_say)
            for i, prefab in ipairs(prefabs) do
                if str_say == STRINGS["WAGSTAFF_NPC_WANT_TOOL_" .. i] then
                    needprefab = prefab
                    break
                end
            end
            for i = 1, 2 do
                if str_say == STRINGS["WAGSTAFF_NPC_EXPERIMENT_DONE_" .. i] or str_say ==
                    STRINGS["WAGSTAFF_NPC_EXPERIMENT_FAIL_" .. i] then
                    done = true
                    break
                end
            end
            if needprefab then
                for i = 1, 2 do
                    if str_say == STRINGS.WAGSTAFF_NPC_YES_THIS_TOOL[i] then
                        needprefab = nil
                        break
                    end
                end
            end
        end)
    end)
end)

local prefab_birds = {"bird_mutant", "bird_mutant_spitter"}
local prefab_npc = "wagstaff_npc"
local function fn()
    local npc = e_util:FindEnt(nil, prefab_npc)
    if not npc then
        Say("没有找到瓦格斯塔夫")
        return
    end
    local pusher = ThePlayer.components.hx_pusher
    if not pusher then
        return
    end
    if pusher:GetNowTask() then
        pusher:StopNowTask()
        return
    end

    local weapon = p_util:GetEquip("hands") 
    if weapon then
        Say(string_task, "启动, 确定武器为" .. weapon.name)
    else
        Say(string_task, "启动")
    end
    local mode = "等待模式" 
    local bird_core, need_item, need_equip
    done = false
    
    
    
    local function SetMode(M)
        Say(M)
        mode = M
    end
    local function EquipAndClick(str_act)
        if e_util:IsValid(need_equip) and e_util:IsValid(need_item) then
            if p_util:GetEquip("hands") ~= need_equip then
                p_util:Equip(need_equip)
                d_util:Wait()
            end
            if p_util:GetEquip("hands") == need_equip then
                if not p_util:TryClick(need_item, str_act) then
                    m_util:print("没有动作！")
                    SetMode("等待模式")
                end
            else
                SetMode("等待模式")
            end
        else
            SetMode("等待模式")
        end
    end
    local function Can_Get_Glass()
        need_item = e_util:FindEnt(nil, "moonglass_charged", 6)
        return need_item and save_data.sw_p
    end
    local function Can_Attack_Bird()
        local bird = e_util:FindEnt(npc, prefab_birds, save_data.bird_warn)
        if bird and save_data.sw_f then
            bird_core = bird:GetPosition()
            return true
        end
    end
    local function Can_Give_NPC()
        if needprefab then
            need_item = p_util:GetItemFromAll(needprefab, nil, nil, "mouse")
            return need_item and save_data.sw_g
        end
    end
    local function Can_Pick_Tool()
        if needprefab then
            need_item = e_util:FindEnt(npc, needprefab, save_data.range_pick) 
            return need_item and save_data.sw_p
        end
    end
    local function Can_Mine_Glass()
        need_item = e_util:FindEnt(npc, "moonstorm_glass", save_data.range_catch, nil, nil, nil, nil, function(ent)
            return not e_util:FindEnt(ent, prefab_birds, 8)
        end)
        if need_item then
            need_equip = p_util:GetItemFromAll(nil, nil, function(equip)
                return p_util:GetAction("useitem", "MINE", false, equip, need_item)
            end, {"equip", "mouse", "container", "backpack", "body"})
            return need_equip and save_data.sw_m
        end
    end
    local function Can_Net_Spark()
        need_item = e_util:FindEnt(npc, "moonstorm_spark", save_data.range_catch, nil, nil, nil, nil, function(ent)
            return not e_util:FindEnt(ent, prefab_birds, 2)
        end)
        if need_item then
            need_equip = p_util:GetItemFromAll(nil, nil, function(equip)
                return p_util:GetAction("useitem", "NET", false, equip, need_item)
            end, {"equip", "mouse", "container", "backpack", "body"})
            return need_equip and save_data.sw_n
        end
    end
    pusher:RegNowTask(function(player, pc)
        if not e_util:IsValid(npc) or done then
            return true
        end
        if mode == "等待模式" then
            if Can_Get_Glass() then
                SetMode("拾取模式")
            elseif Can_Attack_Bird() then
                SetMode("战斗模式")
            elseif Can_Give_NPC() then
                SetMode("递交模式")
            elseif Can_Pick_Tool() then
                SetMode("拾取模式")
            elseif Can_Mine_Glass() then
                SetMode("挖矿模式")
            elseif Can_Net_Spark() then
                SetMode("捕捉模式")
            else
                local pos = c_util:GetIntersectPotRadiusPot(npc:GetPosition(), 3.5, player:GetPosition())
                p_util:Click(pos)
            end
        elseif mode == "战斗模式" then
            local bird = e_util:FindEnt(bird_core, prefab_birds, 9)
            if bird then
                
                if e_util:IsValid(weapon) and p_util:GetEquip("hands") ~= weapon then
                    p_util:Equip(weapon)
                    d_util:Wait()
                end
                
                if p_util:AttackInRange(bird) then
                    pc:DoAttackButton(bird)
                else
                    p_util:Click(bird)
                end
            else
                SetMode("等待模式")
            end
        elseif mode == "递交模式" then
            if e_util:IsValid(need_item) and need_item:HasTag("inlimbo") then
                if d_util:TakeActiveItem(need_item) then
                    m_util:print("拿取物品失败！")
                    SetMode("等待模式")
                else
                    if not p_util:TryClick(npc, "GIVE") then
                        SetMode("等待模式")
                    end
                end
            else
                SetMode("等待模式")
            end
        elseif mode == "拾取模式" then
            p_util:ReturnActiveItem()
            if e_util:IsValid(need_item) and not need_item:HasTag("inlimbo") then
                if not p_util:TryClick(need_item, "PICKUP") then
                    m_util:print("没有拾取动作！")
                    SetMode("等待模式")
                end
            else
                SetMode("等待模式")
            end
        elseif mode == "挖矿模式" then
            EquipAndClick("MINE")
        elseif mode == "捕捉模式" then
            EquipAndClick("NET")
            d_util:Wait(2)
        end
        
        d_util:Wait()
    end, function(player)
        Say(string_task, "结束")
        if e_util:IsValid(player) then
            player:DoTaskInTime(3, function()
                local item = e_util:FindEnt(nil, "moonstorm_static_item")
                if item then
                    p_util:TryClick(item, "PICKUP")
                end
            end)
        end
    end)
end


local font_color = require("data/valuetable").RGB_datatable
local range_table = t_util:BuildNumInsert(5, 80, 5, function(i)
    return {
        data = i,
        description = i
    }
end)
local screen_data = {{
    id = "sw_f",
    label = "战斗模式",
    fn = fn_save("sw_f"),
    hover = "是否自动打鸟",
    default = fn_get
}, {
    id = "sw_g",
    label = "递交模式",
    fn = fn_save("sw_g"),
    hover = "是否自动递交小工具",
    default = fn_get
}, {
    id = "sw_p",
    label = "拾取模式",
    fn = fn_save("sw_p"),
    hover = "是否自动拾取小工具和玻璃石",
    default = fn_get
}, {
    id = "sw_m",
    label = "挖矿模式",
    fn = fn_save("sw_m"),
    hover = "是否自动挖取玻璃石",
    default = fn_get
}, {
    id = "sw_n",
    label = "捕捉模式",
    fn = fn_save("sw_n"),
    hover = "是否自动捕捉月熠",
    default = fn_get
}, {
    id = "tool_tip",
    label = "工具提示",
    fn = fn_save("tool_tip"),
    hover = "是否显示辅助小工具的名字",
    default = fn_get
}, {
    id = "textsize",
    label = "字号：",
    fn = fn_save("textsize"),
    hover = "【工具提示】文字的大小",
    default = fn_get,
    type = "radio",
    data = range_table
}, {
    id = "color_ori",
    label = "默认颜色：",
    fn = fn_save("color_ori"),
    hover = "【工具提示】小工具的提示颜色",
    default = fn_get,
    type = "radio",
    data = font_color
}, {
    id = "color_need",
    label = "高亮颜色：",
    fn = fn_save("color_need"),
    hover = "【工具提示】瓦格斯塔夫需要的工具的颜色",
    default = fn_get,
    type = "radio",
    data = font_color
}, {
    id = "bird_warn",
    label = "警戒范围：",
    fn = fn_save("bird_warn"),
    hover = "月盲乌鸦进入npc此范围则触发人物战斗模式",
    default = fn_get,
    type = "radio",
    data = t_util:BuildNumInsert(6, 60, 2, function(i)
        return {
            data = i,
            description = i
        }
    end)
}, {
    id = "range_pick",
    label = "拾取范围：",
    fn = fn_save("range_pick"),
    hover = "帮瓦格斯塔夫捡工具的范围",
    default = fn_get,
    type = "radio",
    data = range_table
}, {
    id = "range_catch",
    label = "采集范围：",
    fn = fn_save("range_catch"),
    hover = "采集月熠或者挖充能玻璃石的范围",
    default = fn_get,
    type = "radio",
    data = range_table
}}
local func_right = m_util:AddBindShowScreen({
    title = string_task,
    id = "hx_" .. save_id,
    data = screen_data,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "关于",
        fn = function()
            h_util:CreatePopupWithClose(nil,
                "这个功能还能继续优化，目前一顿一顿的。\n优化后的版本参照 静电任务+")
        end
    }, {
        id = "bilibili",
        prefab = "bilibili",
        hover = "教程演示",
        fn = function()
            VisitURL("https://www.bilibili.com/video/BV1jH4y1j7YW/", true)
        end
    }},
    help = "在瓦格斯塔夫被抓走前，使用此功能自动完成静电任务。\n启动本功能时玩家的手部装备，视为用来战斗的武器。"
})

m_util:AddBindConf(save_id, fn, nil,
    {string_task, "moonstorm_static_item", STRINGS.LMB .. '快速开关' .. STRINGS.RMB .. '高级设置', true, fn,
     func_right, 1.2})
