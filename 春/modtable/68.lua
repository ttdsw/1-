local save_id, map_str = "map_gogo", "自动寻路"
local default_data = {
    tele = m_util:IsHuxi(),
    sw = true,
    double = false,
    double_time = 3
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local pos_old

local ui_data = {{
    id = "readme",
    label = "使用说明",
    fn = function()
        h_util:CreatePopupWithClose("自动寻路 · 使用说明",
            "当地图右键有动作时, 右键寻路不会生效，\n你可以改其他按键或者打开下面【双击替换】。")
    end,
    hover = "点击查看教程",
    default = true
}, {
    id = "tele",
    label = "一键传送",
    fn = fn_save("tele"),
    hover = "上帝模式下, 地图寻路直接传送过去\n仅限开洞穴关延迟补偿的情况下！",
    default = fn_get
}, {
    id = "double",
    label = "双击替换",
    fn = fn_save("double"),
    hover = "是否将原版右键单击地图的动作改为双击, 这样恶魔人就可以右键寻路了。\n 注意：丢靴子也会变双击",
    default = fn_get
}, {
    id = "double_time",
    label = "双击间隔：",
    fn = fn_save("double_time"),
    hover = "【双击替换附属功能】右键双击判定的时间间隔",
    default = fn_get,
    type = "radio",
    data = t_util:BuildNumInsert(1, 10, 1, function(t)
        return {
            data = t,
            description = t * 0.1 .. " 秒"
        }
    end)
}}

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegHMap(save_id, map_str, "是否显示 " .. map_str .. " 的图标", function()
        return save_data.sw
    end, fn_save("sw"), {
        screen_data = ui_data,
        nothud = true
    })
end)


local function SetIcon(pos)
    local saver = m_util:GetSaver()
    if not (pos and pos.x and pos.z and saver) then
        return
    end
    local info = {
        x = pos.x,
        z = pos.z,
        icon = "mark_x"
    }
    if pos_old then
        saver:ChanHMap(save_id, {
            x = pos_old.x,
            z = pos_old.z,
            icon = "mark_x"
        }, info)
    else
        saver:AddHMap(save_id, info, true)
    end
    pos_old = pos
end

local function GoTo(pos_target, pc)
    
    local pusher = m_util:GetPusher()
    if not pusher then
        return
    end
    pusher:StopNowTask()

    local pos_init = ThePlayer:GetPosition()
    
    if save_data.tele and not p_util:IsDead() and not pc.locomotor then
        local fnstr =
            "local h = ThePlayer and ThePlayer.Transform and ThePlayer.components.health if h and h:IsInvincible() then ThePlayer.Transform:SetPosition(" ..
                pos_target.x .. ", 0, " .. pos_target.z .. ") end"
        i_util:ExRemote(fnstr)
    end
    
    if pc.locomotor then
        p_util:WalkTo(pos_target)
    else
        local dirx, diry = c_util:GetUnitDirection(pos_init, pos_target)
        SendRPCToServer(RPC.DirectWalking, dirx, diry)
    end
    
    SetIcon(pos_target)
    
    local dist_max = c_util:GetDist(pos_init.x, pos_init.z, pos_target.x, pos_target.z)
    pusher:RegNowTask(function(player, pc)
        d_util:Wait()
        local pos = player:GetPosition()
        return c_util:GetDist(pos.x, pos.z, pos_init.x, pos_init.z) >= dist_max
    end, function(player)
        p_util:StopWalking()
    end)
end
local time_click = 0
AddClassPostConstruct("screens/mapscreen", function(self)
    
    local _OnControl = self.OnControl
    self.OnControl = function(self, ctrl, down, ...)
        if down and ctrl == CONTROL_SECONDARY then
            local pc = ThePlayer and ThePlayer.components.playercontroller
            if not pc then
                return _OnControl(self, ctrl, down, ...)
            end

            local pos_target = Vector3(self:GetWorldPositionAtCursor())
            local lmb, rmb = pc:GetMapActions(pos_target)
            if rmb then
                local now = GetTime()
                local isdouble = now - time_click < save_data.double_time * 0.1
                time_click = now
                
                if save_data.double then
                    
                    if isdouble then
                        
                        p_util:StopWalking()
                    else
                        
                        return GoTo(pos_target, pc)
                    end
                else
                    
                end
            else
                
                GoTo(pos_target, pc)
            end
        end
        return _OnControl(self, ctrl, down, ...)
    end
end)
