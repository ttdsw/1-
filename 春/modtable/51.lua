
if m_util:IsServer() then
    return
end
local save_id, string_cane = "sw_cane", "切个手杖"
local default_data = {
    sw = m_util:IsHuxi() and "on" or "off",
    light_unequip = true,
    right_hold = false
}

local function func_hand(item)
    return e_util:GetItemEquipSlot(item) == "hands" and p_util:GetAction("inv", {"equip", "unequip"}, true, item)
end
local function func_light(item)
    return e_util:IsLightSourceEquip(item) and e_util:GetPercent(item) > 0
end

local slots = {"walk", "attack", "light", "right"}
local act_codes = {"LOOKAT", "WALKTO"}
t_util:IPairs(slots, function(slot)
    default_data["ui_" .. slot] = true
end)
default_data.ui_right = m_util:IsHuxi()
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local function GetEquip(prefab)
    if prefab then
        local NeedAutoUnEquip = Mod_ShroomMilk.Func.NeedAutoUnEquip
        local slot_data = p_util:GetSlotFromAll(prefab, nil, function(item)
            return p_util:GetAction("inv", {"equip", "unequip"}, true, item) and e_util:GetPercent(item) > 0 and
                       (not NeedAutoUnEquip or not NeedAutoUnEquip(item))
        end, {"equip", "body", "backpack", "container", "mouse"})
        if slot_data and not t_util:GetElement(EQUIPSLOTS, function(_, slot)
            return slot == slot_data.slot
        end) then
            return slot_data.item
        end
    end
end
local function EquipIt(prefab)
    local equip = GetEquip(prefab)
    if equip then
        p_util:Equip(equip)
    end
end
local function FilterActs(acts)
    return t_util:IPairFilter(acts or {}, function(act)
        local act_id = t_util:GetRecur(act, "action.id")
        return act_id and not table.contains(act_codes, act_id) and act
    end)
end
local function GetEquipAct(item, target)
    local acts_right = FilterActs(p_util:GetActions("equip", true, item, target))
    local acts_left = FilterActs(p_util:GetActions("equip", false, item, target))
    
    local act_right = t_util:IGetElement(acts_right, function(act_right)
        local r_id = t_util:GetRecur(act_right, "action.id")
        return r_id and not t_util:IGetElement(acts_left, function(act_left)
            return t_util:GetRecur(act_left, "action.id") == r_id
        end) and act_right
    end)
    if act_right then
        return act_right, true
    end
    return acts_left[1], false
end
local function UseEquip(item, target)
    local trans = e_util:IsValid(target)
    if item and trans then
        
        local x, _, z = trans:GetWorldPosition()
        if table.contains({"yellowstaff", "opalstaff", "trident"}, item.prefab) then
            local act = p_util:GetAction("pos", "CASTSPELL", true, item, nil, Vector3(x, 0, z))
            if act then
                p_util:Equip(item)
                return i_util:DoTaskInTime(FRAMES, function()
                    p_util:DoAction(act, RPC.RightClick, act.action.code, x, z)
                end)
            end
        end

        local act, right = GetEquipAct(item, target)
        
        
        if not act and item.prefab == "staff_lunarplant" and target.prefab == "stalker_atrium" and
            e_util:GetPercent(item) > 0 then
            act = BufferedAction(ThePlayer, target, ACTIONS.ATTACK)
        end

        if act then
            p_util:Equip(item)
            
            i_util:DoTaskInTime(FRAMES, function()
                local released = not save_data.right_hold
                if right then
                    p_util:DoAction(act, RPC.RightClick, act.action.code, x, z, target, act.rotation, released, nil,
                        true, act.action.mod_name)
                else
                    p_util:DoAction(act, RPC.LeftClick, act.action.code, x, z, target, released, 10, true,
                        act.action.mod_name)
                end
            end)
        end
    end
end

local atk_target
local function PressAttack()
    if not (save_data.sw == "on" and save_data.ui_attack and m_util:InGame()) then
        return
    end
    local pc = t_util:GetRecur(ThePlayer, "components.playercontroller")
    if pc then
        atk_target = pc:GetCombatTarget() or pc:GetAttackTarget(TheInput:IsControlPressed(CONTROL_FORCE_ATTACK)) or
                         atk_target
        if e_util:IsValid(atk_target) then
            if atk_target:HasOneOfTags({"butterfly", "stalkerminion"}) or atk_target.prefab == "shadowchanneler" then
                return
            end
            local equip = GetEquip(save_data.item_attack)
            if equip then
                if p_util:IsRider() then
                    
                    local range_weapon = p_util:GetWeaponRange(equip.prefab)
                    
                    if range_weapon and range_weapon <= 6 then
                        return
                    end
                end
                p_util:Equip(equip)
                if equip ~= p_util:GetEquip("hands") then
                    local pos = atk_target:GetPosition()
                    p_util:DoAction(BufferedAction(ThePlayer, atk_target, ACTIONS.ATTACK), RPC.LeftClick,
                        ACTIONS.ATTACK.code, pos.x, pos.z, atk_target, true, 10, true, nil, nil, false)
                end
                return true
            end
        end
    end
end
local not_cane_prefabs = {"thurible", "bootleg", "bugnet", "thulecitebugnet", "moonstorm_static_catcher"}
local function PressWalk()
    if not (save_data.sw == "on" and save_data.ui_walk) then
        return
    end
    local hand = p_util:GetEquip("hands")
    if hand then
        if hand:HasOneOfTags({"castfrominventory", "umbrella", "_oceanfishingrod", "fishingrod"}) or
            e_util:HasOneOfComps(hand, {"farmtiller", "wateryprotection", "terraformer", "oar"}) or
            e_util:IsLightSourceEquip(hand) or table.contains(not_cane_prefabs, hand.prefab) then
            return
        end
    end
    if p_util:IsHeavy() then
        return
    end
    EquipIt(save_data.item_walk)
    return true
end

local function ForceEquipWalk()
    if not (save_data.sw == "on" and save_data.ui_walk) then
        return
    end
    local hand = p_util:GetEquip("hands")
    if hand and e_util:IsLightSourceEquip(hand) then
        return
    end
    if p_util:IsHeavy() then
        return
    end
    EquipIt(save_data.item_walk)
    return true
end


Mod_ShroomMilk.Func.ForceEquipWalk = ForceEquipWalk
Mod_ShroomMilk.Func.EquipWalk = PressWalk
Mod_ShroomMilk.Func.EquipAttack = PressAttack

AddComponentPostInit("playercontroller", function(self, player)
    if player ~= ThePlayer then
        return
    end
    local _DoDirectWalking = self.DoDirectWalking
    function self:DoDirectWalking(...)
        if self.directwalking then
            PressWalk()
        elseif TheInput:IsControlPressed(CONTROL_ATTACK) then
            PressAttack()
        end
        return _DoDirectWalking(self, ...)
    end
end)

i_util:AddPlayerActivatedFunc(function(player, world, pusher)
    
    pusher:RegInDark(function(indark)
        if not (save_data.ui_light and save_data.sw == "on") then
            return
        end
        local prefab = save_data.item_light
        if prefab then
            if indark then
                EquipIt(prefab)
            elseif save_data.light_unequip and prefab ~= save_data.item_walk and world:HasTag("forest") then
                local item = p_util:IsEquipped(prefab)
                if item then
                    p_util:UnEquip(item, true)
                    if save_data.ui_walk then
                        EquipIt(save_data.item_walk)
                    end
                end
            end
        end
    end)
end)

i_util:AddRightClickFunc(function(pc, player, down, act_right, ent_mouse)
    if not (down and ent_mouse and save_data.ui_right and save_data.sw == "on" and
        not TheInput:IsControlPressed(CONTROL_FORCE_TRADE)) then
        return
    end
    local prefab = save_data.item_right
    if prefab then
        local item = p_util:IsEquipped(prefab)
        if item then
            UseEquip(item, ent_mouse)
        else
            
            if not act_right or t_util:IGetElement(act_codes, function(str)
                return ACTIONS[str] == act_right.action
            end) then
                UseEquip(GetEquip(prefab), ent_mouse)
            end
        end
    end
end)

i_util:AddPlayerActivatedFunc(function(player)
    local ectrl = h_util:GetECtrl()
    if ectrl then
        ectrl:ResetIcon()
    end
end)


local data_slots = {
    walk = {
        hover = "用来【跑路】的装备",
        label = "跑路栏",
        filter = func_hand,
        work = function()
            for control = CONTROL_MOVE_UP, CONTROL_MOVE_RIGHT do
                if TheInput:IsControlPressed(control) then
                    EquipIt(save_data.item_walk)
                end
            end
        end
    },
    attack = {
        hover = "用来【攻击】的武器",
        label = "战斗栏",
        filter = func_hand
    },
    light = {
        hover = "用来【照明】的装备",
        label = "照明栏",
        filter = func_light
    },
    right = {
        hover = "【右键】触发的装备",
        label = "右键栏",
        filter = func_hand
    }
}


local funcs_ui = {
    SavePos = function(pos)
        fn_save("posx")(pos.x)
        fn_save("posy")(pos.y)
    end,
    SaveData = fn_save
}
AddClassPostConstruct("widgets/inventorybar", function(self, player)
    if self.ectrl then
        self.ectrl:Kill()
    end
    self.ectrl = self:AddChild(require("widgets/huxi/huxi_ectrl")(self, player, save_data, funcs_ui, {
        slots = slots,
        data_slots = data_slots
    }))
end)


local function fn()
    local value = save_data.sw == "on" and "off" or "on"
    local show = value == "on"
    fn_save("sw")(value)
    local ectrl = h_util:GetECtrl()
    if not ectrl then
        return
    end
    ectrl:UI_Build(save_data)
    u_util:Say(string_cane, show, nil, nil, true)
end
local screen_data = {{
    id = "sw",
    label = "总开关",
    hover = "一键开关所有功能",
    default = function()
        return save_data.sw == "on"
    end,
    fn = fn
}, {
    id = "resetpos",
    label = "重置UI位置",
    hover = "如果卡键了，请点击我！",
    default = true,
    fn = function()
        local ectrl = h_util:GetECtrl()
        if ectrl then
            ectrl:ResetPos()
        end
    end
}}
t_util:IPairs(slots, function(slot)
    local id = "ui_" .. slot
    local data = data_slots[slot]
    table.insert(screen_data, {
        id = id,
        label = data.label,
        hover = "是否显示" .. data.hover,
        default = fn_get,
        fn = function(value)
            fn_save(id)(value)
            local ectrl = h_util:GetECtrl()
            if ectrl then
                ectrl:UI_Build(save_data)
            end
        end
    })
end)
table.insert(screen_data, {
    id = "light_unequip",
    label = "卸载照明",
    hover = "天亮或者有光时卸载正在装备的照明【仅限地表】",
    default = fn_get,
    fn = fn_save("light_unequip")
})
table.insert(screen_data, {
    id = "right_hold",
    label = "右键持续工作",
    hover = "【仅限开洞穴而且没开独行长路的世界】\n右键栏的装备是否连续生效\n喜欢打怪就关此选项, 习惯工作就开启此选项",
    default = fn_get,
    fn = fn_save("right_hold")
})

local fn_right = m_util:AddBindShowScreen({
    title = string_cane,
    id = "hx_" .. save_id,
    data = screen_data,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "自动吃饭",
        fn = function()
            h_util:CreatePopupWithClose("自动吃饭 提示",
                "该功能已经单独放在面板了，所以移除了旧版【干饭栏】")
        end
    }, {
        id = "bilibili",
        prefab = "bilibili",
        hover = "教程演示",
        fn = function()
            VisitURL("https://www.bilibili.com/video/BV1aKCXB3EAJ", true)
        end
    }}
})
m_util:AddBindConf(save_id, fn, nil,
    {string_cane, "cane_candycane", STRINGS.LMB .. '快速开关  ' .. STRINGS.RMB .. '高级设置', true, fn,
     fn_right, 7992})
