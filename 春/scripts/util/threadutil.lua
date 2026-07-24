




local p_util = require "util/playerutil"
local e_util = require "util/entutil"
local m_util = require "util/modutil"
local c_util = require "util/calcutil"
local t_util = require "util/tableutil"
local m_func = Mod_ShroomMilk.Func

local d_util = {
    time_wait = FRAMES * 3,
    time_out = 1,
    dist_click = 60,
    time_check = FRAMES * 10,
}

local rpc_timestamp = "_hx_timestamp"
local rpc_data = "_hx_rpc_data"

local function GetCurrentScheduler()
    local co = coroutine.running()
    if co then
        if scheduler.tasks[co] then
            return scheduler
        elseif staticScheduler.tasks[co] then
            return staticScheduler
        end
    end
end


function d_util:Wait(time_wait)
    time_wait = time_wait or d_util.time_wait
    time_wait = time_wait < 0 and d_util.time_wait or time_wait
    if GetCurrentScheduler() then
        
        Sleep(time_wait)
    else
        print("Sleep 不应该在主线程中调用！请联系开发者修复！")
    end
end



function d_util:TaskLoop(func, time_wait, time_out)
    local time_start = GetTime()
    time_out = time_out or self.time_out
    while func() do
        self:Wait(time_wait)
        if GetTime() - time_start > time_out then
            return true
        end
    end
end



function d_util:TaskCheck(func_task, func_check, time_wait, time_out, time_check)
    time_out = time_out or self.time_out
    time_check = time_check or self.time_check
    local time_start = GetTime()
    local time_loop = time_start
    func_task()
    while func_check() do
        local now = GetTime()
        if now - time_start > time_out then
            return true
        elseif now - time_loop > time_check then
            func_task()
            time_loop = now
        end
        self:Wait(time_wait) 
    end
end




function d_util:TakeActivePrefab(item, ...)
    local prefab = item and item.prefab
    if not prefab then return true end
    local item_active = p_util:GetActiveItem()
    local data = p_util:GetSlotFromAll(nil, nil, function(ent)
        return ent == item
    end, "mouse")
    if data then
        local cont, slot = data.cont, data.slot
        if slot == "mouse" then return end
        if type(slot) == "number" then
            return self:TaskLoop(function()
                if item_active then
                    
                    if item_active.prefab == item.prefab then
                        return
                    else
                        self:SwapActiveItemWithSlot(cont, slot)
                    end
                else
                    p_util:TakeActiveItemFromAllOfSlot(cont, slot)
                end
                item_active = p_util:GetActiveItem()
                return item_active ~= item
            end, ...)
        else
            
            return self:TaskLoop(function()
                if item_active then
                    if e_util:GetItemEquipSlot(item_active) == e_util:GetItemEquipSlot(item) then
                        self:SwapActiveItemWithSlot(cont, slot)
                    else
                        p_util:ReturnActiveItem()
                    end
                else
                    p_util:TakeActiveItemFromAllOfSlot(cont, slot)
                end
                item_active = p_util:GetActiveItem()
                return item_active ~= item
            end, ...)
        end
    end
    return true
end



function d_util:TakeActiveItem(item, ...)
    local data = p_util:GetSlotFromAll(nil, nil, function(ent)
        return ent == item
    end, "mouse")
    if data then
        local cont, slot = data.cont, data.slot
        if slot == "mouse" then return end
        local item_active = p_util:GetActiveItem()
        if type(slot) == "number" then
            return self:TaskLoop(function()
                if item_active then
                    
                    if item_active.prefab == item.prefab and item.skinname == item_active.skinname and e_util:GetStackSize(item) ~= 1 then
                        p_util:ReturnActiveItem()
                    else
                        self:SwapActiveItemWithSlot(cont, slot)
                    end
                else
                    p_util:TakeActiveItemFromAllOfSlot(cont, slot)
                end
                item_active = p_util:GetActiveItem()
                return item_active ~= item
            end, ...)
        else
            
            return self:TaskLoop(function()
                if item_active then
                    if e_util:GetItemEquipSlot(item_active) == e_util:GetItemEquipSlot(item) then
                        self:SwapActiveItemWithSlot(cont, slot)
                    else
                        p_util:ReturnActiveItem()
                    end
                else
                    p_util:TakeActiveItemFromAllOfSlot(cont, slot)
                end
                item_active = p_util:GetActiveItem()
                return item_active ~= item
            end, ...)
        end
    else
    end
    return true
end



function d_util:TakeActiveItemFromCountOfSlot(cont, slot, count, ...)
    
    return self:TaskLoop(function()
        p_util:TakeActiveItemFromCountOfSlot(cont, slot, count)
        return not p_util:GetActiveItem()
    end)
end


function d_util:PutOneOfActiveItemInSlot(cont, slot, ...)
    if p_util:GetActiveItem() then
        local item_cont = p_util:GetItemInSlot(cont, slot)
        local item_size = item_cont and e_util:GetStackSize(item_cont) or 0

        return self:TaskLoop(function()
            p_util:PutOneOfActiveItemInSlot(cont, slot)
            local item_cont_new = p_util:GetItemInSlot(cont, slot)
            local item_size_new = item_cont_new and e_util:GetStackSize(item_cont_new) or 0
            return item_size == item_size_new
        end, ...)
    end
    return true
end


function d_util:PutActiveItemInSlot(cont, slot, ...)
    local item_active = p_util:GetActiveItem()
    local size_active = e_util:GetStackSize(item_active)
    if item_active then
        local item_to = p_util:GetItemInSlot(cont, slot)
        return self:TaskLoop(function()
            if item_to then
                if item_to.prefab == item_active.prefab and item_to.skinname == item_active.skinname then
                    local size_max, size_stack = e_util:GetMaxSize(item_to), e_util:GetStackSize(item_to)                   
                    if size_max > size_stack then
                        
                        p_util:PutAllOfActiveItemInSlot(cont, slot)
                        item_active = p_util:GetActiveItem()
                        
                        return item_active and size_active == e_util:GetStackSize(item_active)
                    else
                        
                        if size_max == 1 then
                            
                            return self:SwapActiveItemWithSlot(cont, slot, item_to)
                        else
                            
                            return
                        end
                    end
                else
                    
                    return self:SwapActiveItemWithSlot(cont, slot, item_to)
                end
            else
                
                p_util:PutAllOfActiveItemInSlot(cont, slot)
                return not p_util:GetItemInSlot(cont, slot)
            end
        end, ...)
    end
end




function d_util:SwapActiveItemWithSlot(cont, slot, item_to)
    return self:TaskCheck(function()
        p_util:SwapActiveItemWithSlot(cont, slot)
    end, function()
        return p_util:GetActiveItem() ~= item_to
    end)
end


function d_util:MoveItemInSlot(item, cont, slot, ...)
    local item_to = p_util:GetItemInSlot(cont, slot)
    if not item_to or item_to.prefab ~= item.prefab then
        return self:TakeActiveItem(item, ...) or self:PutActiveItemInSlot(cont, slot, ...)
    end
end


function d_util:ReturnActiveItem(...)
    if p_util:GetActiveItem() then
        return self:TaskLoop(function()
            p_util:ReturnActiveItem()
            return p_util:GetActiveItem()
        end, ...)
    end
end


function d_util:MakeItem(prefab,skin, ...)
    local time_wait, time_out = ...
    time_wait = time_wait or 3*FRAMES
    time_out = time_out or 5

    self:TaskLoop(function()
        if not p_util:GetItemFromAll(prefab) then p_util:MakeSth(prefab, skin) return true end
    end, time_wait, time_out)
end


function d_util:QueryShowme(target, time_wait, time_out)
    time_wait = time_wait or FRAMES
    time_out = time_out or 1
    local data
    self:TaskLoop(function()
        data = m_util:QueryShowme(target)
        return not data
    end, time_wait, time_out)
    return data
end




function d_util:SceneNear(dist_near, fn_check, ...)
    return self:TabNear(dist_near, fn_check, function()return true end, ...)
end







function d_util:TabNear(dist_near, fn_check, fn_repeat, ...)
    local args = {...}
    local target = args[1]
    local function _fn_check()
        return not t_util:IGetElement(args, function(target)
            return not e_util:IsValid(target)
        end) and (not fn_check or fn_check(unpack(args)))
    end
    local flag_walk
    
    while _fn_check() do
        local pt, pp = target:GetPosition(), ThePlayer:GetPosition()
        local dist = c_util:GetDist(pt.x, pt.z, pp.x, pp.z)
        if dist > dist_near then
            if m_func.ForceEquipWalk then
                m_func.ForceEquipWalk()
            end
            if t_util:GetRecur(ThePlayer, ".components.locomotor") then
                p_util:DoAction(BufferedAction(ThePlayer, nil, ACTIONS.WALKTO, nil, pt), RPC.LeftClick, ACTIONS.WALKTO.code, pt.x, pt.z)
            else
                if dist > 60 then
                    local dirx, diry = c_util:GetUnitDirection(pp, pt)
                    SendRPCToServer(RPC.DirectWalking, dirx, diry)
                    flag_walk = true
                else
                    if flag_walk then
                        SendRPCToServer(RPC.StopWalking)
                    end
                    SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pt.x, pt.z)
                end
            end
        elseif fn_repeat() then
            return true
        end
        d_util:Wait()
    end
end


function d_util:SpaceScene(target, code_act, fn_check)
    if self:SceneNear(4, fn_check, target) then
        local act = p_util:GetAction("scene", code_act, false, target) or p_util:GetAction("scene", code_act, true, target)
        if act then
            local acts = p_util:GetAction(nil, target) or {}
            if acts.rmb and acts.rmb.action == act.action then
                p_util:DoAction(act, RPC.ControllerAltActionButton, ACTIONS[code_act].code, target, nil, nil, act.action.mod_name)
            else
                p_util:DoAction(act, RPC.ControllerActionButton, ACTIONS[code_act].code, target, nil, true, act.action.mod_name)
            end
        else
            return true
        end
    end
end
function d_util:TabScene(target, code_act, fn_check)
    return self:TabNear(4, fn_check, function()
        local act = p_util:GetAction("scene", code_act, false, target) or p_util:GetAction("scene", code_act, true, target)
        if act then
            
            
            
            p_util:DoAction(act, RPC.ActionButton, ACTIONS[code_act].code, target, nil, true, act.action.mod_name)
        else
            return true
        end
    end, target)
end


function d_util:TabPickUp(target)
    return self:TabScene(target, "PICKUP", function()return not target:HasTag("inlimbo")end)
end
function d_util:TabGive(target, useitem)
    return self:TabUseItem(target, useitem, "GIVE", function(target, useitem)return useitem:HasTag("inlimbo")end)
end
function d_util:TabUseItem(target, useitem, code_act, fn_check)
    return self:TabNear(4, fn_check, function()
        local act = p_util:GetAction("useitem", code_act, true, useitem, target) or p_util:GetAction("useitem", code_act, false, useitem, target)
        if act then
            p_util:DoAction(act, RPC.ControllerUseItemOnSceneFromInvTile, ACTIONS[code_act].code, useitem, target, act.action.mod_name)
        else
            return true
        end
    end, target, useitem)
end

function d_util:TabEquipTarget(target, equip, code_act, fn_check)
    return self:TabNear(6, fn_check, function()
        if p_util:GetEquip("hands") == equip then
            local left = p_util:GetAction("equip", code_act, false, equip, target)
            local right = not left and p_util:GetAction("equip", code_act, true, equip, target)
            
            
            local pos = target:GetPosition()
            if right then
                p_util:DoAction(right, RPC.RightClick, right.action.code, pos.x, pos.z, target, right.rotation, nil, nil, true, right.action.mod_name)
            elseif left then
                p_util:DoAction(left, RPC.LeftClick, left.action.code, pos.x, pos.z, target, nil, nil, true, left.action.mod_name)
            else
                return true
            end
        else
            p_util:Equip(equip)
        end
    end, target, equip)
end


function d_util:TabEquipSingle(target, equip, code_act, fn_check)
    return self:TabNear(4, fn_check, function()
        if p_util:GetEquip("hands") == equip then
            local act = p_util:GetAction("equip", code_act, true, equip, target) or p_util:GetAction("equip", code_act, false, equip, target)
            if act then
                
                
                
                
                p_util:DoAction(act, RPC.ActionButton, ACTIONS[code_act].code, target, nil, nil, act.action.mod_name)
            else
                return true
            end
        else
            p_util:Equip(equip)
        end
    end, target, equip)
end
function d_util:SpaceUseitem(useitem, target, code_act, fn_check)
    if self:SceneNear(4, fn_check, target, useitem) then
        local act = p_util:GetAction("useitem", code_act, true, useitem, target) or p_util:GetAction("useitem", code_act, false, useitem, target)
        if act then
            p_util:DoAction(act, RPC.ControllerUseItemOnSceneFromInvTile, ACTIONS[code_act].code, useitem, target, act.action.mod_name)
        else
            return true
        end
    end
end

function d_util:SpacePickUp(target)
    return self:SpaceScene(target, "PICKUP", function(target)
        return not target:HasTag("inlimbo")
    end)
end


function d_util:TabAttack(atkrange, target)
    return self:TabNear(atkrange, function() return p_util:CanAttack(target) end, function()p_util:Attack(target)end, target)
end

function d_util:TabWeaponAtk(weapon, target)
    
    local range_weapon = self:WaitWeaponRange(weapon)
    local range_target = e_util:IsValid(target) and target:GetPhysicsRadius(0)
    if range_weapon and range_target then
        return self:TabNear(range_weapon+range_target, function() return p_util:CanAttack(target) end, function()
            if p_util:GetEquip("hands") ~= weapon then
                p_util:Equip(weapon)
            end
            p_util:Attack(target)
        end, target)
    end
end



function d_util:WaitWeaponRange(weapon)
    local range_weapon = p_util:GetWeaponRange(weapon.prefab)
    if range_weapon then
        return range_weapon
    else
        self:TaskLoop(function()
            p_util:Equip(weapon)
            return not p_util:GetWeaponRange(weapon.prefab) and e_util:IsValid(weapon)
        end, FREMES, .5)
        return p_util:GetWeaponRange(weapon.prefab)
    end
end




function d_util:RemoteClick(data)
    local inst = data.target
    local dist = e_util:GetDist(inst)
    if not m_util:GetMovementPrediction() and dist and dist > self.dist_click then
        local dirx, diry = c_util:GetUnitDirection(ThePlayer:GetPosition(), inst:GetPosition())
        SendRPCToServer(RPC.DirectWalking, dirx, diry)
        local pusher = m_util:GetPusher()
        if pusher then
            pusher:RegNowTask(function()
                local dist = e_util:GetDist(inst)
                if dist then
                    if dist < self.dist_click then
                        p_util:StopWalking()
                        p_util:DoMouseAction(data.act, data.right)
                        return true
                    end
                else
                    return true
                end
                self:Wait()
            end)
        end
    else
        p_util:DoMouseAction(data.act, data.right)
    end
end



function d_util:OpenContainer(target)
    local time_click, pos_lastsend = 0, ThePlayer:GetPosition()
    repeat
        local cont = p_util:IsOpenContainer(target)
        if cont then
            
            return cont
        else
            local now = GetTime()
            if now - time_click > .5 then
                local pos_player = ThePlayer:GetPosition()
                local dist = e_util:GetDist(target)
                
                if c_util:GetDist(pos_lastsend.x, pos_lastsend.z, pos_player.x, pos_player.z) < .5 or (dist and dist > 6) then
                    local act, right = p_util:GetMouseActionSoft({"RUMMAGE"}, target)
                    if act then
                        p_util:DoMouseAction(act, right)
                    else
                        return
                    end
                end
                time_click, pos_lastsend = now, pos_player
            end
        end
        self:Wait()
    until not (e_util:IsValid(target) and p_util:GetMouseActionSoft({"RUMMAGE"}, target))
end

return d_util