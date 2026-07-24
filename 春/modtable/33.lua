

local count = 0
local id_thread, loop_thread
local time_take = 0
local ItemTile = require "widgets/itemtile"
local ItemSlot = require "widgets/invslot"
local InvBar = require "widgets/inventorybar"

local tile_loc

local function SetQuantity(tile, num)
    if h_util:IsValid(tile) then
        tile:SetQuantity(num)
    end
end

local function NumReset()
    count = 0
end

local function StopLoopThread()
    if loop_thread then
        KillThreadsWithID(id_thread)
        loop_thread = nil
        if h_util:IsValid(tile_loc) then
            tile_loc:Kill()
        end
    end
    NumReset()
end
local function IsInvSlot(w)
    if w and w.is_a then
        if w:is_a(ItemSlot) then
            return true
        elseif w:is_a(InvBar) then
            return false
        else
            return IsInvSlot(w.parent)
        end
    end
end

AddClassPostConstruct("widgets/invslot", function(self)
    local function FnTake(num)
        count = count + num
        local now = GetTime()
        local tile_slot = self.tile
        local item_slot = self.tile and self.tile.item
        local item_mouse = p_util:GetActiveItem()
        local item_has = item_slot or item_mouse
        if not item_has then
            return NumReset()
        end
        local sound = item_has.pickupsound or "DEFAULT_FALLBACK"
        sound = PICKUPSOUNDS[sound]
        local count_mouse = e_util:GetStackSize(item_mouse)
        local count_slot = e_util:GetStackSize(item_slot)

        
        if item_mouse then
            if item_slot then
                if item_slot.prefab ~= item_mouse.prefab or item_slot.skinname ~= item_mouse.skinname then
                    
                elseif count_mouse + count_slot > e_util:GetMaxSize(item_slot) then
                    
                    if count < 0 then
                    else
                        
                    end
                else
                    local tile_mouse = t_util:GetRecur(ThePlayer, "HUD.controls.inv.hovertile")
                    SetQuantity(tile_mouse, count_mouse + count)
                    SetQuantity(tile_slot, -count)
                end
            else
                
                
                if not h_util:IsValid(tile_loc) then
                    tile_loc = self:AddChild(ItemTile(item_mouse))
                    tile_loc:SetClickable(false)
                end
                local tile_mouse = t_util:GetRecur(ThePlayer, "HUD.controls.inv.hovertile")
                SetQuantity(tile_mouse, count_mouse + count)
                SetQuantity(tile_loc, -count)
            end
        else 
            local data = p_util:GetSlotFromAll(nil, nil, function(ent)
                return ent == item_slot
            end)
            local mf = t_util:GetRecur(ThePlayer, "HUD.controls.mousefollow")
            if data and mf then
                
                
                if not h_util:IsValid(tile_loc) then
                    tile_loc = mf:AddChild(ItemTile(item_slot))
                    tile_loc.isactivetile = true
                    
                end
                SetQuantity(tile_loc, count)
                SetQuantity(tile_slot, count_slot - count)
                h_util:PlaySound(sound)
            end
        end

        if loop_thread then
        else
            loop_thread = StartThread(function()
                d_util:Wait()
                local hud = TheInput:GetHUDEntityUnderMouse()
                t_util:FEP(TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition()))

                if hud and hud.widget then
                    print(hud.widget.parent.parent)
                end
                if IsInvSlot(hud and hud.widget) then
                else
                    return StopLoopThread()
                end
            end, id_thread)
        end
    end

    local _OnMouseButton = self.OnMouseButton
    self.OnMouseButton = function(self, btn, ...)
        local ret = _OnMouseButton(self, btn, ...)
        if btn == MOUSEBUTTON_SCROLLUP then
            FnTake(-1)
        elseif btn == MOUSEBUTTON_SCROLLDOWN then
            FnTake(1)
        end
        return ret
    end
end)

