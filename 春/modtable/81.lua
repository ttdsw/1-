local CPS = require "widgets/huxi/huxi_compass"
local save_id, str_show = "sw_compass", "指南针"
local default_data = {
    
    scale = 2,
    offset = not m_util:IsHuxi(),
    text = true,
    shake = true,
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local UI_funcs = {
    SavePos = function(pos)
        fn_save("posx")(pos.x)
        fn_save("posy")(pos.y)
    end
}

local function GetCPS()
    local cps = h_util:GetControls().hx_compass
    return cps and h_util:IsValid(cps)
end

local function MakeCPS()
    local ctrls = t_util:GetRecur(ThePlayer, "HUD.controls")
    if ctrls then
        ctrls.hx_compass = ctrls:AddChild(CPS(UI_funcs, save_data))
    end
end

local function fn_set(id)
    return function(val)
        fn_save(id)(val)
        local cps = GetCPS()
        if cps then
            cps:Kill()
            MakeCPS()
        end
    end
end

local function fn_left()
    local cps = GetCPS()
    if cps then
        cps:Kill()
        u_util:Say(str_show, "关闭", nil, "红色", true)
    else
        MakeCPS()
        u_util:Say(str_show, "开启", nil, "绿色", true)
    end
end

local screen_data = {
    {
        id = "reset",
        label = "重置指南针位置",
        hover = "如果图标位置有错乱，请尝试此选项",
        fn = function()
            local cps = GetCPS()
            if cps then
                cps:SetUIPos(true)
            else
                u_util:Say(str_show, "您尚未开启该功能", "self", "红色", true)
            end
        end,
        prefab = "compass",
        type = "imgstr",
    },
    {
        id = "scale",
        label = "指南针缩放：",
        hover = "调节指南针的大小",
        fn = fn_set("scale"),
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(0.1, 4, 0.1, function(i)
            return {data = i, description = i}
        end)
    },
    {
        id = "shake",
        label = "真实的模拟",
        hover = "指南针是否摇晃\n 该选项禁用后，下个选项也将无法生效",
        fn = fn_set("shake"),
        default = fn_get,
    },
    {
        id = "offset",
        label = "更加真实的模拟",
        hover = "理智和月相将会影响指南针的角度\n 再启用此选项，就和原版指南针一模一样了",
        fn = fn_set("offset"),
        default = fn_get,
    },
    {
        id = "text",
        label = "用数字显示数据",
        hover = "是否有数字显示明确方位",
        fn = fn_set("text"),
        default = fn_get,
    },
    {
        id = "readme",
        label = "快点我！",
        fn = function()
            h_util:CreatePopupWithClose("󰀍"..str_show.." · 特别鸣谢󰀍",
                "该功能由玩家 猫头军师 特别定制\n\n留言：喵喵喵，喵喵喵喵，喵喵！！")
        end,
        hover = "特别鸣谢",
        default = true
    },
}
local fn_right = m_util:AddBindShowScreen({
    title = str_show,
    id = "hx_" .. save_id,
    data = screen_data,
                icon = 
    {{
        id = "add",
        prefab = "mods",
        hover = "计时器",
        fn = function()
            h_util:CreatePopupWithClose(nil, "尚未有人定制此功能，敬请期待。")
        end,
    }},
})
m_util:AddBindConf(save_id, fn_left, nil, {str_show, "compass",
                                           STRINGS.LMB .. '快捷开关' .. STRINGS.RMB .. '高级设置', true,
                                           fn_left, fn_right, 2997})