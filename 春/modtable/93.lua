local save_id, str_show = "sw_tumbleweed", "风滚草预测"

local default_data = {
    tag = true,
    say = true,
}
local prefab_weed = "tumbleweed"
local high_weed = "hl_tumbleweed"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local time_record = 0
local time_short = 0.5
local pos_num = 4          
local pos_tws = {}
local list_data = {}
local tags = {}

local function fn_check(pos, now)
    
    if now - time_record > time_short then return end
    return not t_util:IGetElement(pos_tws, function(ipos)
        return c_util:GetDist(pos.x, pos.z, ipos.x, ipos.z) > 8
    end)
end
local function fn_tag(posc)
    if not save_data.tag then return end
    if not m_util:InGame() then return end
    local pid = c_util:GetPosID(posc.x, posc.z)
    if not tags[pid] then
        local tag_tw = e_util:SpawnFx("hx_tumbleweed", "tumbleweed", "tumbleweed", "move_loop", h_util:GetRGB("绿色"), .3)
        tag_tw.Transform:SetPosition(posc.x, 0, posc.z)
        tags[pid] = tag_tw
    end
end
i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegHMap(save_id, str_show, "是否显示 "..str_show.." 的图标", saver:GetHMapSWFunc(save_id))
    
    list_data = saver:GetList(save_id, true)
    
    t_util:IPairs(list_data, function(info)
        saver:AddHMap(save_id, {
            x = info.x,
            z = info.z,
            icon = high_weed
        })
        
        
    end)
end)


local check_range, time_count = 64, 0
i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    pusher:RegPerPos(function(x, z)
        
        time_count = time_count + 1
        if time_count < 5 then return end
        time_count = 0
        
        t_util:IPairs(list_data, function(info)
            if c_util:GetDist(x, z, info.x, info.z) < check_range then
                fn_tag(info)
            end
        end)
    end)
end)

local function fn_spawn(posc)
    
    fn_tag(posc)
    if save_data.say then
        u_util:Say(str_show, "已生成标记")
    end
    
    local saver = m_util:GetSaver()
    if not saver then return end
    saver:AddHMap(save_id, {x = posc.x, z = posc.z, icon = high_weed}, true)
    
    
    for i = #list_data, 1, -1 do
        local ipos = list_data[i]
        if c_util:GetDist(posc.x, posc.z, ipos.x, ipos.z) < 2 then
            saver:RemoveHMap(save_id, {x = ipos.x, z = ipos.z, icon = high_weed})
            table.remove(list_data, i)
        end
    end

    
    table.insert(list_data, {x = tonumber(string.format("%.2f", posc.x)), z = tonumber(string.format("%.2f", posc.z))})
end

local function fn_weed(inst)
    if m_util:IsHost() then return end
    inst:DoTaskInTime(.1, function(inst)
        local pos = inst.Transform and inst:GetPosition()
        if type(pos)~="table" or pos.x == 0 then return end
        local now = GetTime()
        if not fn_check(pos, now) then pos_tws = {} end
        time_record = now
        table.insert(pos_tws, pos)
        if #pos_tws ~= pos_num then return end
        
        local posc = {}
        t_util:IPairs(pos_tws, function(ipos)
            if posc.x and posc.z then
                posc.x, posc.z = (posc.x + ipos.x)/2, (posc.z + ipos.z)/2
            else
                t_util:EasyCopy(posc, ipos)
            end
        end)
        
        fn_spawn(posc)
    end)
end

AddPrefabPostInit(prefab_weed, fn_weed)
AddPrefabPostInit(prefab_weed.."spawner", function(inst)
    if m_util:IsHost() then
        inst:DoTaskInTime(.1, function(inst)
            local pos = inst.Transform and inst:GetPosition()
            if type(pos)~="table" or pos.x == 0 then return end
            
            fn_spawn(pos)
        end)
    end
end)

local screen_data = {
    {
        id = "tag",
        label = "显示场地标记",
        hover = "是否在地上显示绿色的 "..str_show.." 的标记",
        default = fn_get,
        fn = function(show)
            fn_save("tag")(show)
            if not show then
                t_util:Pairs(tags, function(pid, tag)
                    tag:Remove()
                end)
                tags = {}
            end
        end
    },
    {
        id = "mapshow",
        label = "显示地图图标",
        hover = "是否显示 "..str_show.." 的地图图标",
        default = function()
            local saver = m_util:GetSaver()
            if not saver then return end
            return saver:GetHMapSW(save_id)
        end,
        fn = function(show)
            local saver = m_util:GetSaver()
            if not saver then return end
            if not saver:SetHMapSW(save_id, show) then
                h_util:CreatePopupWithClose("提示", "地图图标功能被禁用，请检查您的设置。")
            end
        end
    },
    {
        id = "say",
        label = "显示提示信息",
        hover = "生成标记时是否提示文字信息",
        default = fn_get,
        fn = fn_save("say")
    },{
        id = "remove",
        label = "清除风滚草记忆",
        hover = "清理本地存储的风滚草标记记忆",
        type = "imgstr",
        prefab = prefab_weed,
        fn = function()
            h_util:CreatePopupWithClose("警告", "你确定要清理存储的所有刷新点位置吗？\n新的刷新点标记需要风滚草再次刷新才会生成", {
                {text = "取消"},
                {text = "我确定！", cb = function()
                    t_util:Pairs(tags, function(pid, tag)
                        tag:Remove()
                    end)
                    tags = {}
                    local saver = m_util:GetSaver()
                    if not saver then return end
                    t_util:Clear(list_data)
                    saver:ClearHMap(save_id)
                    h_util:PlaySound("learn_map")
                end}
            })
        end
    }
}


local fn_right = m_util:AddBindShowScreen{
    title = str_show,
    id = "hx_" .. save_id,
    data = screen_data
}
m_util:AddBindConf(save_id, fn_right, nil, {str_show, prefab_weed,
                                           STRINGS.LMB .. '标记设置', true, fn_right,})