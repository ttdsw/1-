local ents_listen = {}
local prefabs_sea = {"underwater_salvageable"}
local dist_show = 6
local dist_hide = 2.5 

AddPrefabPostInit("winch", function(inst)
    inst._harrow = inst:SpawnChild("harrow")
    local arrow, arrow_tf = inst._harrow,  inst._harrow.Transform
    arrow:Hide()
    arrow_tf:SetScale(1, 3, 1)
    inst:DoPeriodicTask(3*FRAMES, function(inst)
        local pos = inst:GetPosition()
        local dist_near = dist_show
        local ent_near
        t_util:Pairs(ents_listen, function(ent)
            local trans = e_util:IsValid(ent)
            if trans then
                local x, _, z = trans:GetWorldPosition()
                local dist_ent = c_util:GetDist(pos.x, pos.z, x, z)
                if dist_ent < dist_near then
                    dist_near = dist_ent
                    ent_near = ent
                end
            end
        end)
        if ent_near then
            if dist_near > dist_hide then
                arrow:Show()
                arrow:Link(inst, ent_near)
                h_util.SetAddColor(inst)
            else
                h_util.SetAddColor(inst, "绿色")
                arrow:Hide()
            end
        else
            arrow:Hide()
            h_util.SetAddColor(inst)
        end
    end)
end)

t_util:IPairs(prefabs_sea, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        local pusher = m_util:GetPusher()
        if not pusher then return end
        pusher:RegNearStart(inst, function()
            ents_listen[inst] = true
        end, function()
            ents_listen[inst] = nil
        end)
    end)
end)