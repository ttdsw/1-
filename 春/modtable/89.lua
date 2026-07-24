local previews = {}
local turf_size = 4
local turf_grid_radius = 10
local tiles_id = {GROUND.OCEAN_START, GROUND.OCEAN_COASTAL, GROUND.OCEAN_COASTAL_SHORE}


local function fn_clear()
    t_util:IPairs(previews, function(preview)
        preview:Remove()
    end)
    previews = {}
end
local function fn_preview()
    fn_clear()
    local cx, _, cz = TheWorld.Map:GetTileCenterPoint(ThePlayer.Transform:GetWorldPosition())
    local radius = turf_grid_radius * turf_size
    for x = cx - radius, cx + radius + turf_size, turf_size do
        for z = cz - radius, cz + radius + turf_size, turf_size do
            if table.contains(tiles_id, TheWorld.Map:GetTileAtPoint(x, 0, z)) then
                local hkit = SpawnPrefab("hfloorkit")
                hkit.Transform:SetPosition(x, 0, z)
                table.insert(previews, hkit)
            end
        end
    end
end




i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    player:ListenForEvent("refreshinventory", function()
        local item = p_util:GetActiveItem()
        if item and item.prefab == "dock_kit" then
            fn_preview()
            e_util:SetBindEvent(item, "stacksizedirty", fn_preview)
        else
            fn_clear()
        end
    end)
end)