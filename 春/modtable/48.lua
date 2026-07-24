
local save_id, str_show, logo = "sw_hideshadow", "隐藏影怪", "skeletonhat"
local prefabs = {"crawlinghorror", "terrorbeak", 
"crawlingnightmare", "nightmarebeak", 
"oceanhorror", 
"ruinsnightmare", 
"shadowskittish", 
"gestalt_guard", 
"gestalt", 
"gestalt_guard_evolved" 
}
local SW
local function func(inst)
    if SW then
        inst:Hide()
        if inst.SoundEmitter then
            inst.SoundEmitter:SetMute(true)
        end
    else
        inst:Show()
        if inst.SoundEmitter then
            inst.SoundEmitter:SetMute(false)
        end
    end
end

t_util:IPairs(prefabs, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoPeriodicTask(FRAMES, func)
    end)
end)

local function fn_sw(value)
    SW = not SW
    u_util:Say(str_show, SW, nil, nil, true)
    t_util:IPairs(e_util:FindEnts(nil, prefabs, nil, {}, {}, nil, {}), func)
end

m_util:AddBindConf(save_id, fn_sw, nil,
    {str_show, logo, STRINGS.LMB .. "开关(重进游戏自动关闭)", true, fn_sw, function()
        h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍",
            "本模组功能由金主 花间随柳 定制。\n(其实该功能还能隐藏月灵)", {{
                text = "󰀍"
            }})
    end, 8002})
