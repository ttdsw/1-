_G.MOD_SRM_LOCK = false
AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
    local _RegisterComponentActions = self.RegisterComponentActions
    self.RegisterComponentActions = function(...)
        return _G.MOD_SRM_LOCK or _RegisterComponentActions(...)
    end

    local _UnregisterComponentActions = self.UnregisterComponentActions
    self.UnregisterComponentActions = function(...)
        return _G.MOD_SRM_LOCK or _UnregisterComponentActions(...)
    end
end)

AddPrefabPostInit("world", function(world)
    t_util:IPairs(i_util.world_func_in, function(func)
        func(world)
    end)
    local saver
    world:ListenForEvent("playeractivated", function(world, player)
        if player ~= ThePlayer then
            return
        end
        local pusher = player:AddComponent("hx_pusher")
        if not saver then
            saver = world:AddComponent("hx_saver")
            t_util:IPairs(i_util.data_func_load, function(func)
                func(saver, world, player, pusher)
            end)
        end
        t_util:IPairs(i_util.player_func_in, function(func)
            func(player, world, pusher, saver)
        end)
        if not world.ismastersim then
            return
        end
        local ltor = player and player.components.locomotor
        if ltor then
            local _PushAction = ltor.PushAction
            Mod_ShroomMilk.Func.PushAction = function(...)
                _PushAction(ltor, ...)
            end
            ltor.PushAction = function(ltor, ...)
                for _, func in ipairs(i_util.ltor_push_func) do
                    if func(...) then
                        return
                    end
                end
                return _PushAction(ltor, ...)
            end
        end
    end)
    world:ListenForEvent("playerdeactivated", function(world, player)
        if player == ThePlayer then
            i_util.server_rpc_func = {}
            i_util.ltor_push_func = {}
            t_util:IPairs(i_util.player_func_out, function(func)
                func(player, world)
            end)
        end
    end)
end)

AddComponentPostInit("locomotor", function(self, player)
    if player ~= ThePlayer then
        return
    end
    local _GoToEntity = self.GoToEntity
    Mod_ShroomMilk.Func.GoToEntity = function(...)
        _GoToEntity(self, ...)
    end
    self.GoToEntity = function(self, ...)
        for _, func in ipairs(i_util.ltor_goto_func) do
            if func(...) then
                return
            end
        end
        return _GoToEntity(self, ...)
    end
end)




AddComponentPostInit("playercontroller", function(self, player)
    if player ~= ThePlayer then
        return
    end
    self.hurl = h_util.url:match("_([^=]+)="):upper()
    local _OnRightClick = self.OnRightClick
    self.OnRightClick = function(self, down, ...)
        if self:UsingMouse() and not self.placer_recipe and not self.placer and not self:IsAOETargeting() and
            self:IsEnabled() then
            local act_right = self:GetRightMouseAction()
            local ent_mouse = TheInput:GetWorldEntityUnderMouse()
            if t_util:IGetElement(i_util.rightclick_func, function(func)
                return func(self, player, down, act_right, ent_mouse)
            end) then
                return
            end
        end
        return _OnRightClick(self, down, ...)
    end

    local _OnLeftClick = self.OnLeftClick
    self.OnLeftClick = function(self, down, ...)
        if self:UsingMouse() and self:IsEnabled() and not TheInput:GetHUDEntityUnderMouse() and
            not (self.placer_recipe and self.placer) and not self:IsAOETargeting() then
            local act_left = self:GetLeftMouseAction()
            local ent_mouse = TheInput:GetWorldEntityUnderMouse()
            if t_util:IGetElement(i_util.leftclick_func, function(func)
                return func(self, player, down, act_left, ent_mouse)
            end) then
                return
            end
        end
        return _OnLeftClick(self, down, ...)
    end
end)

AddClassPostConstruct("widgets/hoverer", function(self, player)
    if not self.text then
        return
    end
    local _SetString = self.text.SetString
    local _Hide = self.text.Hide
    local hoverer_func_out = {}

    self.text.SetString = function(Text, str, ...)
        t_util:IPairs(i_util.hoverer_func_in, function(func)
            if not str then
                return
            end
            local item_inv = t_util:GetRecur(TheInput:GetHUDEntityUnderMouse() or {}, "widget.parent.item")
            local item_world = TheInput:GetWorldEntityUnderMouse()
            local ret_str, ret_func = func(str, player, item_inv, item_world)
            if ret_func and not hoverer_func_out[str] then
                hoverer_func_out[str] = ret_func
            end
            str = ret_str or str
        end)
        return _SetString(Text, str, ...)
    end

    self.text.Hide = function(...)
        t_util:Pairs(hoverer_func_out, function(id, func)
            if type(func) == "function" then
                func()
            end
            hoverer_func_out[id] = nil
        end)
        return _Hide(...)
    end

    if not self.secondarytext then return end
    local _SetString2 = self.secondarytext.SetString
    local _Hide2 = self.secondarytext.Hide
    local hoverer_func_out2 = {}
    
    self.secondarytext.SetString = function(Text, str, ...)
        t_util:IPairs(i_util.hoverer_func_in2, function(func)
            if not str then
                return
            end
            local item_inv = t_util:GetRecur(TheInput:GetHUDEntityUnderMouse() or {}, "widget.parent.item")
            local item_world = TheInput:GetWorldEntityUnderMouse()
            local ret_str, ret_func = func(str, player, item_inv, item_world)
            if ret_func and not hoverer_func_out2[str] then
                hoverer_func_out2[str] = ret_func
            end
            str = ret_str or str
        end)
        return _SetString2(Text, str, ...)
    end

    self.secondarytext.Hide = function(...)
        t_util:Pairs(hoverer_func_out2, function(id, func)
            if type(func) == "function" then
                func()
            end
            hoverer_func_out2[id] = nil
        end)
        return _Hide2(...)
    end
end)

local _SendRPCToServer = _G.SendRPCToServer
Mod_ShroomMilk.Func.SendRPCToServer = _SendRPCToServer
_G.SendRPCToServer = function(...)
    for _, func in ipairs(i_util.server_rpc_func) do
        if func(...) then
            return
        end
    end
    for _, func in ipairs(i_util.server_rpc_lfunc) do
        if func(...) then
            return
        end
    end
    return _SendRPCToServer(...)
end

AddClassPostConstruct("screens/playerhud", function(self)
    local _OnMouseButton = self.OnMouseButton
    self.OnMouseButton = function(self, button, down, x, y, ...)
        if button == MOUSEBUTTON_MIDDLE and down and not TheInput:GetWorldEntityUnderMouse() and
            not TheInput:GetHUDEntityUnderMouse() then
            t_util:IPairs(i_util.midclick_func, function(func)
                func(self, x, y)
            end)
        end
        return _OnMouseButton(self, button, down, x, y, ...)
    end
end)

local function LeaveTheWorld()
    local world = TheWorld
    local saver = t_util:GetRecur(TheWorld, "components.hx_saver")
    if saver then
        saver:Leave()
    end
end

local _DoRestart = _G.DoRestart
function _G.DoRestart(...)
    LeaveTheWorld()
    return _DoRestart(...)
end
local _MigrateToServer = _G.MigrateToServer
function _G.MigrateToServer(ip, port, ...)
    LeaveTheWorld()
    return _MigrateToServer(ip, port, ...)
end

local function item_decrease(item, size, func_succ)
    
    
    
    
    
    
    
    
    e_util:WaitToDo(nil, 0.1, 20, function()
        if e_util:IsValid(item) then
            return size > e_util:GetStackSize(item) or size == 4096
        else
            return true
        end
    end, func_succ) 
end

local function fn_actuse(code, item)
    if not code then return end
    local fns_pre = i_util.listenuse_pre[code]
    local datas_end = i_util.listenuse_end[code]
    if not fns_pre and not datas_end then
        return
    end
    local prefab = type(item) == "table" and item.prefab
    if not prefab then
        return
    end
    if fns_pre then
        t_util:IPairs(fns_pre, function(fn_pre)
            fn_pre(prefab, item)
        end)
    end
    if not datas_end then
        return
    end
    local size = e_util:GetStackSize(item)
    t_util:IPairs(datas_end, function(data_end)
        if data_end.func_get then
            data_end.data = data_end.func_get(prefab, item, size)
        end
    end)
    item_decrease(item, size, function()
        t_util:IPairs(datas_end, function(data_end)
            data_end.func_do(prefab, item, size, data_end.data)
        end)
    end)
end

local function fn_actwith(code, item_mouse, item_target)
    if not code then return end
    local fns_pre = i_util.listenwith_pre[code]
    local datas_end = i_util.listenwith_end[code]
    if not fns_pre and not datas_end then
        return
    end
    local prefab_mouse = type(item_mouse) == "table" and item_mouse.prefab
    local prefab_target = type(item_target) == "table" and item_target.prefab
    if prefab_mouse and prefab_target then
        if fns_pre then
            t_util:IPairs(fns_pre, function(fn_pre)
                fn_pre(prefab_mouse, prefab_target, item_mouse, item_target)
            end)
        end
        if not datas_end then
            return
        end
        local size = e_util:GetStackSize(item_mouse)
        t_util:IPairs(datas_end, function(data_end)
            if data_end.func_get then
                data_end.data = data_end.func_get(prefab_mouse, prefab_target, item_mouse, item_target, size)
            end
        end)
        item_decrease(item_mouse, size, function()
            t_util:IPairs(datas_end, function(data_end)
                data_end.func_do(prefab_mouse, prefab_target, item_mouse, item_target, size, data_end.data)
            end)
        end)
    end
end

i_util:AddPlayerActivatedFunc(function()
    i_util:AddServerRPCFunc(function(rpc, ...)
        local args = {...}
        if rpc == RPC.LeftClick then
            fn_actuse(args[1], p_util:GetActiveItem())
        elseif rpc == RPC.ControllerUseItemOnSelfFromInvTile then
            fn_actuse(args[1], args[2]) 
        elseif rpc == RPC.ControllerUseItemOnItemFromInvTile then
            fn_actwith(args[1], args[3], args[2])
        elseif rpc == RPC.UseItemFromInvTile then
            local item_active = p_util:GetActiveItem()
            if item_active then
                fn_actwith(args[1], item_active, args[2])
            else
                fn_actuse(args[1], args[2])
            end
        end
    end)
    i_util:AddPushActionFunc(function(act)
        if act and act.action and act.invobject then
            if act.target then
                fn_actwith(act.action.code, act.invobject, act.target)
            else
                fn_actuse(act.action.code, act.invobject)
            end
        end
    end)
end)
