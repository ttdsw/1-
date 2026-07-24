local fov_min, fov_max = 20, 179
local isbigger = m_util:IsTurnOn("c_init") or m_util:IsHuxi()
if not m_util:IsMilker() and m_util:IsHuxi() then
    print("开发者模式启用, 大视野启用")
end

local function c_fov(delta)
    local fov = TheCamera.fov + delta
    fov = fov < fov_min and fov_min or fov
    fov = fov > fov_max and fov_max or fov
    TheCamera.fov = fov
    u_util:Say("FOV", fov, "head", nil, true)
end

m_util:AddBindConf("c_add", function()
    c_fov(1)
end, true)
m_util:AddBindConf("c_minus", function()
    c_fov(-1)
end, true)
m_util:AddBindConf("c_hidehud", function()
    if ThePlayer.HUD:IsVisible() then
        ThePlayer.HUD:Hide()
        ThePlayer.HUD.under_root:Hide()
        u_util:Say("截图模式", "隐藏HUD", "head", "蓟色", true)
    else
        ThePlayer.HUD:Show()
        ThePlayer.HUD.under_root:Show() 
        u_util:Say("截图模式", "显示HUD", "head", "蓟色", true)
    end
end)
m_util:AddBindConf("c_hideself", function()
    if ThePlayer.entity:IsVisible() then
        ThePlayer:Hide()
        ThePlayer.DynamicShadow:Enable(false)
        u_util:Say("截图模式", "隐藏玩家", "head", "蓟色", true)
    else
        ThePlayer:Show()
        ThePlayer.DynamicShadow:Enable(true)
        u_util:Say("截图模式", "显示玩家", "head", "蓟色", true)
    end
end)
local c_follow_ent, null_target
m_util:AddBindConf("c_track", function()
    local ent = TheInput:GetWorldEntityUnderMouse()
    if e_util:IsValid(ent) then
    else
        local pos = TheInput:GetWorldPosition()
        if not null_target then
            null_target = e_util:SpawnNull()
            null_target.entity:AddTransform()
        end
        null_target.Transform:SetPosition(pos:Get())
        null_target.name = tostring(pos)
        ent = null_target
    end
    TheCamera:SetTarget(ent)
    c_follow_ent = ent
    u_util:Say("视角追踪", ent.name, "self", "蓟色", true)
end)
m_util:AddBindConf("c_back", function()
    if TheCamera.target ~= ThePlayer then
        TheCamera:SetTarget(ThePlayer)
        u_util:Say("视角回切", ThePlayer.name, "self", "蓟色", true)
    elseif c_follow_ent then
        if c_follow_ent == null_target then
            TheCamera:SetTarget(c_follow_ent)
            u_util:Say("追踪位置", c_follow_ent:GetPosition(), "self", "蓟色", true)
        elseif e_util:IsValid(c_follow_ent) then
            TheCamera:SetTarget(c_follow_ent)
            u_util:Say("视角追踪", c_follow_ent.name, "self", "蓟色", true)
        else
            u_util:Say("视角追踪", "目标无效", "self", "红色", true)
        end
    end
end)

local argu = {"zoomstep", "mindist", "maxdist", "mindistpitch", "maxdistpitch", "distance", "distancetarget", "fov"}

local args_default = {}

local value_bigger_forest = {10, 10, 180, 30, 60, 80, 80, 35}
local value_bigger_cave = {10, 10, 180, 25, 40, 80, 80, 35}

local value_overlook = {10, 10, 180, 90, 90, 80, 80, 35}

local value_eagle = {10, 10, 180, 90, 90, 80, 80, 170}

local function SetView(vt)
    if TheCamera then
        for k, v in ipairs(argu) do
            rawset(TheCamera, v, vt[k])
        end
    end
end

AddClassPostConstruct('cameras/followcamera', function(self)
    local _Update = self.Update
    self.Update = function(...)
        if self.target and self.target.Transform then
            local x, y, z = self.target.Transform:GetWorldPosition()
            if not (x and y and z) then
                self:SetTarget(ThePlayer)
            end
        end
        t_util:Pairs(argu, function(num, key)
            self[key] = self[key] or args_default[key] or value_bigger_forest[num]
        end)
        return _Update(...)
    end

    local _SetDefault = self.SetDefault
    self.SetDefault = function(...)
        local ret = _SetDefault(...)
        if t_util:GetSize(args_default) == 0 then
            t_util:IPairs(argu, function(id)
                local value = self[id]
                if type(value) == "number" then
                    args_default[id] = value
                end
            end)
        end
        return ret
    end

    local _GetDistance = self.GetDistance
    self.GetDistance = function(...)
        return _GetDistance(...) or self.distancetarget or 80
    end
end)

i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    if not isbigger then return end
    
    player:DoTaskInTime(.1, function()
        if world:HasTag("cave") then
            SetView(value_bigger_cave)
        else
            SetView(value_bigger_forest)
        end
    end)
end)

local hanzify = {"默认", "大视野", "俯视", "鹰眼"}
local loca_mode = isbigger and 2 or 1
local change_mode = m_util:IsTurnOn("change_mode") or 1
local modetable = {{1, 2, 3}, {1, 2}, {1, 3}, {2, 3}}

local function SetMode(mode)
    if not TheWorld then
        return
    end
    if mode ~= 4 then
        u_util:Say(hanzify[mode], nil, nil, nil, true)
    end
    if ThePlayer._hx_label then
        ThePlayer._hx_label:Kill()
        ThePlayer._hx_label = nil
    end
    if mode == 1 then
        SetView(t_util:IPairToIPair(argu, function(id)
            return args_default[id] or value_bigger_forest[id]
        end))
    elseif mode == 2 then
        if TheWorld:HasTag("cave") then
            SetView(value_bigger_cave)
        else
            SetView(value_bigger_forest)
        end
    elseif mode == 3 then
        SetView(value_overlook)
    elseif mode == 4 then
        h_util:CreateLabel(ThePlayer, hanzify[mode], {
            x = 0,
            y = 0
        })
        SetView(value_eagle)
    end
end

local function ChangeView(mt, mode)
    local st = mt[mode] or mt[1]
    loca_mode = st[t_util:GetNextLoopKey(st, t_util:GetElement(st, function(k, v)
        return v == loca_mode and k
    end))]
    SetMode(loca_mode)
end

m_util:AddBindConf("c_change", function()
    ChangeView(modetable, change_mode)
end, true)

Mod_ShroomMilk.Func.ChangeMetaView = ChangeView
