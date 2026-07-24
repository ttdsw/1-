if m_util:IsServer() then return end
local save_id = "sw_catcher"
local string_task = "静电任务+"
local default_data = {
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
local prefab_core = "moonstorm_static_nowag"
local prefab_birds = {"bird_mutant", "bird_mutant_spitter"}
local function Say(who, what)
    u_util:Say(who, what, nil, nil, true)
end



local function fn()
    local pusher = m_util:GetPusher()
    if not pusher then return end
    if pusher:GetNowTask() then
        return pusher:StopNowTask()
    end
    local core = e_util:FindEnt(nil, prefab_core)
    if not core then
        return Say("找不到 "..e_util:GetPrefabName(prefab_core))
    end
    local weapon = p_util:GetEquip("hands")
    if not weapon or type(weapon.name)~="string" then
        return Say("请先装备武器")
    end
    Say("启动, 确定武器为 "..weapon.name)
    local mode = "等待模式"
    local bird_core, item_give, item_tool, item_mine, equip_mine, item_net, equip_net
    
    
    
    
    local function SetMode(M)
        Say(M)
        mode = M
    end

    local function Can_Attack_Bird()
        bird_core = save_data.sw_f and e_util:FindEnt(core, prefab_birds, save_data.bird_warn)
        return bird_core
    end
    local function Can_Give_NPC()
        item_give = save_data.sw_g and e_util:GetAnim(core) == "needtool_idle" and p_util:GetItemFromAll(nil, "wagstafftool")
        return item_give
    end
    local function Can_Pick_Tool()
        
        item_tool = save_data.sw_p and not p_util:GetItemFromAll(nil, "wagstafftool") and e_util:FindEnt(core, nil, save_data.range_pick, {"wagstafftool"})
        return item_tool
    end
    local function Can_Mine_Glass()
        
        item_mine = save_data.sw_m and e_util:FindEnt(core, "moonstorm_glass", save_data.range_catch, nil, nil, nil, nil, function(ent)
            return not e_util:FindEnt(ent, prefab_birds, 8)
        end)
        
        equip_mine = item_mine and p_util:GetItemFromAll(nil, nil, function(equip)
                return p_util:GetAction("equip", "MINE", false, equip, item_mine)
            end, {"equip", "mouse", "container", "backpack", "body"})
        return equip_mine
    end
    local function Can_Net_Spark()
        
        item_net = save_data.sw_n and e_util:FindEnt(core, "moonstorm_spark", save_data.range_catch, nil, nil, nil, nil, function(ent)
            return not e_util:FindEnt(ent, prefab_birds, 2)
        end)
        
        equip_net = item_net and p_util:GetItemFromAll(nil, nil, function(equip)
                return p_util:GetAction("equip", "NET", false, equip, item_net)
            end, {"equip", "mouse", "container", "backpack", "body"})
        return equip_net
    end


    local mv = m_util:GetMovementPrediction()
    m_util:SetMovementPrediction(false)
    pusher:RegNowTask(function(player)
        if not e_util:IsValid(core) or p_util:GetActiveItem() then
            return true
        end
        if mode == "等待模式" then 
            
            if Can_Give_NPC() then
                SetMode("递交模式")
            elseif Can_Attack_Bird() then
                SetMode("战斗模式")
            elseif Can_Pick_Tool() then
                SetMode("拾取工具")
            
            elseif Can_Mine_Glass() then
                SetMode("挖矿模式")
            elseif Can_Net_Spark() then
                SetMode("捕捉模式")
            else
                
                local pos = c_util:GetIntersectPotRadiusPot(core:GetPosition(), 3.5, player:GetPosition())
                p_util:ForceWalkTo(pos)
            end
        elseif mode=="战斗模式" then
            bird_core = e_util:FindEnt(bird_core, prefab_birds, 9)
            if bird_core then
                d_util:TabWeaponAtk(weapon, bird_core)
            else
                SetMode("等待模式")
            end
        elseif mode=="递交模式" then
            d_util:TabGive(core, item_give)
            SetMode("等待模式")
        elseif mode == "拾取工具" then
            d_util:TabPickUp(item_tool)
            SetMode("等待模式")
        elseif mode == "挖矿模式" then
            d_util:TabEquipTarget(item_mine, equip_mine, "MINE")
            SetMode("拾取矿石")
        elseif mode == "拾取矿石" then
            local item_glass = e_util:FindEnt(nil, "moonglass_charged", 4)
            if item_glass then
                d_util:TabPickUp(item_glass)
            else
                SetMode("等待模式")
            end
        elseif mode == "捕捉模式" then
            d_util:TabEquipSingle(item_net, equip_net, "NET")
            SetMode("等待模式")
        end
        d_util:Wait()
    end, function()
        m_util:SetMovementPrediction(mv)
        Say("停止")
    end)
end



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
    label = "拾取工具",
    fn = fn_save("sw_p"),
    hover = "是否自动拾取小工具",
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
        id = "bilibili",
        prefab = "bilibili",
        hover = "教程演示",
        fn = function()
           VisitURL("https://www.bilibili.com/video/BV16ymkBuEKn/", true)
        end,
    },{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", '本功能由玩家"饭港鬼影诺梦"定制。\n\n留言："注意废料消耗"', {{text = "󰀍"}})
        end,
    }},
    help = "在瓦格斯塔夫被抓走后，使用此功能自动完成静电任务。\n启动本功能时玩家的手部装备，视为用来战斗的武器。"
})

m_util:AddBindConf(save_id, fn, nil,
    {string_task, "moonstorm_static_catcher_item", STRINGS.LMB .. '快速开关' .. STRINGS.RMB .. '高级设置', true, fn,
     func_right, 1.1})