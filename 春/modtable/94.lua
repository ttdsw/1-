local save_id, map_str = "map_cavehole", "洞穴楼梯标记"
local default_data = {
    sw = true,
    addcolor = true,
    addtext = true,
    time_diff = 60,
    scale = 17,
}
local id_series = "series_cavehole"


local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local prefabs_hole = {"cave_entrance_open", "cave_exit"}
local map_data, series_data = {}, {}
local function IsCave()
    return TheWorld and TheWorld:HasTag("cave")
end

local function GetIcon(num)
    local iscave = IsCave()
    local prefix = iscave and "cave_up_" or "cave_down_"
    num = type(num) == "number" and num <= 10 and num or "x"
    return prefix..num
end
local function GetNewNum()
    local num = 1
    local iscave = IsCave()
    for _, info in pairs(map_data) do
        
            if type(info.num) == "number" and info.num >= num then
                num = info.num + 1
            end
        
    end
    return num > 10 and "x" or num
end
local Colors = {"红色", "呼吸橙", "金黄色", 
                "绿色", "呼吸蓝", "亮蓝色", 
                "呼吸紫", "蓝色", "呼吸白", 
                "墨绿色", "半白"}

local function AddStyle(inst, num)
    h_util.SetAddColor(inst, save_data.sw and save_data.addcolor and (Colors[num] or Colors[#Colors]))
    h_util:AddText(inst, save_data.sw and save_data.addtext and num, nil, nil, nil, Colors[num] or Colors[#Colors])
end
local function ChanWormholes()
    t_util:IPairs(e_util:FindEnts(nil, prefabs_hole), function(inst)
        local pid = e_util:GetPosID(inst)
        if not pid then return end
        local info = map_data[pid]
        if info then
            AddStyle(inst, info.num)
        end
    end)
end

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegHMap(save_id, map_str, "是否显示 "..map_str.." 的图标", saver:GetHMapSWFunc(save_id), nil,{
    scale = save_data.scale * 0.1, 
    screen_data = {{
            id = "addcolor",
            label = "楼梯洞穴染色",
            fn = function(v)
                fn_save("addcolor")(v)
                ChanWormholes()
            end,
            hover = "是否给楼梯或者洞穴染色",
            default = fn_get
        }, {
            id = "addtext",
            label = "游历标记数字",
            fn = function(v)
                fn_save("addtext")(v)
                ChanWormholes()
            end,
            hover = "是否给楼梯洞穴标记数字",
            default = fn_get
        }, {
            id = "scale",
            label = "标记图标大小：",
            fn = fn_save("scale"),
            hover = "【重启游戏】后生效\n 推荐去【地图图标】设置【所有图标大小】,而不是修改这个",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(1, 50, 1, function(i)
                return {
                    data = i,
                    description = i .. " 像素"
                }
            end)
        },{
            id = "time_diff",
            label = "跨世界间隔：",
            fn = fn_save("time_diff"),
            hover = "距离上次游历世界的时间间隔",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(2, 200, 2, function(i)
                return {
                    data = i,
                    description = i .. " 秒"
                }
            end)
        },{
            id = "reset",
            label = "清理楼梯洞穴标记",
            hover = "如果图标位置有错乱，请尝试此选项",
            fn = function()
                h_util:CreatePopupWithClose("警告", "你确定要清理存储的所有楼梯洞穴标记吗？\n新的标记需要重新上下洞穴才会生成", {
                {text = "取消"},
                {text = "我确定！", cb = function()
                    local saver = m_util:GetSaver()
                    if not saver then return end
                    t_util:Clear(map_data)
                    t_util:Clear(series_data)
                    saver:ClearHMap(save_id)
                    h_util:PlaySound("learn_map")
                    t_util:IPairs(e_util:FindEnts(nil, prefabs_hole), function(inst)
                        h_util.SetAddColor(inst)
                        h_util:AddText(inst)
                    end)
                end}
            })
            end,
            prefab = "cave_entrance",
            type = "imgstr",
        },}})
    
    map_data = saver:GetMap(save_id)
    series_data = saver:GetLine(id_series)
    local iscave = world:HasTag("cave")
    t_util:Pairs(map_data, function(pid, info)
        if info.iscave == iscave then
            saver:AddHMap(save_id, {
                x = info.x,
                z = info.z,
                icon = GetIcon(info.num)
            })
        end
    end)
end)



t_util:IPairs(prefabs_hole, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(2, function()
            local pid = e_util:GetPosID(inst)
            if not pid then return end
            
            local info = map_data[pid]
            if info then
                
                AddStyle(inst, info.num)
            else
                
                local iscave = IsCave()
                local pos = inst:GetPosition()
                
                if iscave ~= series_data.iscave and pos then
                    
                    if type(series_data.time) == "number" and os.time() - series_data.time < save_data.time_diff then
                        AddStyle(inst, series_data.num) 
                        
                        local saver = m_util:GetSaver()
                        if saver then
                            saver:AddHMap(save_id, { x = pos.x, z = pos.z, icon = GetIcon(series_data.num) }, true)
                        end
                        
                        local sx, sz = c_util:GetStardPos(pos.x, pos.z)
                        map_data[pid] = { x = sx, z = sz, num = series_data.num, iscave = iscave }
                        local cid = c_util:GetPosID(series_data.x, series_data.z)
                        map_data[cid] = {x = series_data.x, z = series_data.z, num = series_data.num, iscave = series_data.iscave}
                    end
                end
                series_data.time = nil
            end
        end)
    end)
end)

t_util:IPairs({"multiplayer_portal", "multiplayer_portal_moonrock"}, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(2, function()
            if type(series_data.time) == "number" and os.time() - series_data.time < save_data.time_diff and series_data.iscave ~= IsCave() then
                
                local cid = c_util:GetPosID(series_data.x, series_data.z)
                map_data[cid] = {x = series_data.x, z = series_data.z, num = "x", iscave = series_data.iscave}
            else
                m_util:print("大门标记失败！", type(series_data.time) == "number")
                if type(series_data.time) == "number" then
                    m_util:print(os.time() - series_data.time < save_data.time_diff, series_data.iscave ~= IsCave())
                end
            end
            series_data.time = nil
        end)
    end)
end)

local function Click(down, ent, act)
    if down and ent and act and act.action == ACTIONS.MIGRATE then
        if table.contains(prefabs_hole, ent.prefab) then
            
            local pid = e_util:GetPosID(ent)
            if pid then
                local iscave = IsCave()
                local info = map_data[pid]
                if info and info.iscave == iscave then
                    
                else
                    
                    series_data.time = os.time() 
                    series_data.iscave = iscave  
                    local pos = ent:GetPosition()
                    series_data.x, series_data.z = c_util:GetStardPos(pos.x, pos.z) 
                    
                    series_data.num = GetNewNum()
                end
            end
        end
    end
end
i_util:AddLeftClickFunc(function(pc, player, down, act, ent)
    Click(down, ent, act)
end)
i_util:AddRightClickFunc(function(pc, player, down, act, ent)
    Click(down, ent, act)
end)