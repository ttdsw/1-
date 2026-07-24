local save_id, map_str = "map_animal", "更多生物图标"
local default_data = {
    sw = true,
    range_merge = 8,
    check_time = 3
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local prefabs_data = require("data/mapicons").prefabs_data
local prefabs_map = {}


t_util:Pairs(prefabs_data, function(k, v)
    if type(v) == "string" then
        if type(k) == "number" then
            prefabs_map[v] = v
        elseif type(k) == "string" then
            prefabs_map[k] = v
        end
    end
end)

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    local function MapMoreScreenDataFn()
        local screen_data = { 
        
        
        
        
        
        
        
        
        
        
        
        
        
        {
            id = "check_time",
            label = "图标检查：",
            fn = fn_save("check_time"),
            hover = "遍历检查图标真实性的时间\n 设置越大越流畅，但是越不精准（默认5秒）",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(1, 10, 1, function(i)
                return {
                    data = i,
                    description = i .. " 秒"
                }
            end)
        }}
        t_util:Pairs(prefabs_map, function(prefab, icon)
            local xml, tex, name = h_util:GetPrefabAsset(icon)
            if xml then
                table.insert(screen_data, {
                    id = icon,
                    label = name,
                    hover = "是否显示 " .. name .. " 的图标\n修改设置需要重启游戏后生效！",
                    fn = fn_save(icon),
                    default = function()
                        return c_util:NilIsTrue(save_data[icon])
                    end
                })
            end
        end)
        return screen_data
    end
    
    saver:RegHMap(save_id, map_str, "是否显示 " .. map_str .. " 的图标", function()
        return save_data.sw
    end, fn_save("sw"), {
        screen_data = MapMoreScreenDataFn
    })
    
    local map_data = saver:GetList(save_id, true)
    t_util:IPairs(map_data, function(info)
        if c_util:NilIsTrue(save_data[info.icon]) then
            saver:AddHMap(save_id, info)
        end
    end)

    
    saver:RegSaveFunc(function()
        t_util:Pairs(map_data, function(k)
            map_data[k] = nil
        end)
        t_util:Pairs(saver:GetHMapData(save_id) or {}, function(_, info)
            table.insert(map_data, {
                x = tonumber(string.format("%.2f", info.x)),
                z = tonumber(string.format("%.2f", info.z)),
                icon = info.icon
            })
        end)
    end)
end)


local Intors = {}
local check_range, time_count = 64, 0
local function InIntors(info)
    return t_util:GetElement(Intors, function(inst, info_i)
        return info_i.x == info.x and info_i.z == info.z and info_i.icon == info.icon
    end)
end
i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    pusher:RegPerPos(function(x, z)
        
        time_count = time_count + 1
        if time_count < save_data.check_time then
            return
        end
        time_count = 0
        
        t_util:Pairs(saver:GetHMapData(save_id) or {}, function(_, info)
            if c_util:GetDist(x, z, info.x, info.z) < check_range and not InIntors(info) then
                saver:RemoveHMap(save_id, info)
            end
        end)
        
        t_util:Pairs(Intors, function(inst, info)
            local trans = e_util:IsValid(inst)
            if not trans then
                return
            end
            local x, _, z = trans:GetWorldPosition()
            local info_new = {
                x = x,
                z = z,
                icon = info.icon
            }
            saver:ChanHMap(save_id, info, info_new)
            Intors[inst] = info_new
        end)
    end)
end)


t_util:Pairs(prefabs_map, function(prefab, icon)
    if c_util:NilIsTrue(save_data[icon]) then
        AddPrefabPostInit(prefab, function(inst)
            inst:DoTaskInTime(0, function()
                local pusher = m_util:GetPusher()
                if not pusher then
                    return
                end
                pusher:RegNearStart(inst, function(x, z)
                    
                    local info = {
                        x = x,
                        z = z,
                        icon = icon
                    }
                    local saver = m_util:GetSaver()
                    if saver and saver:AddHMap(save_id, info, true) then
                        
                        Intors[inst] = info
                    end
                end, function()
                    local info = Intors[inst]
                    if not info then
                        return
                    end
                    
                    Intors[inst] = nil
                    
                    if e_util:IsAnim(function(anim)
                        return anim:find("death")
                    end, inst) or e_util:GetLeaderTarget(inst) then
                        local saver = m_util:GetSaver()
                        if saver then
                            saver:RemoveHMap(save_id, info)
                        end
                    end
                    
                end, check_range)
            end)
        end)
    end
end)

