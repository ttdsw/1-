i_util:AddRightClickFunc(function(pc, player, down, act_right, ent)
    if ent and act_right and act_right.action == ACTIONS.CASTSPELL and not ent:HasTag("player") then
        local equip = p_util:GetEquip("hands")
        if equip and equip.prefab == "telestaff" then
            local pos = ent:GetPosition()
            e_util:WaitToDo(player, 0.1, 100, function()
                if e_util:IsValid(ent) then
                    local _pos = ent:GetPosition()
                    if c_util:GetDist(pos.x, pos.z, _pos.x, _pos.z) > 20 then
                        return true
                    else
                        pos = _pos
                    end
                else
                    return true
                end
            end, function()
                SpawnPrefab("reticule").Transform:SetPosition(pos.x, 0, pos.z)
                u_util:Say("传送标记", pos, "self", "紫色", true)
            end)
        end
    end
end)
