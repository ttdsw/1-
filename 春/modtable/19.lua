if m_util:IsServer() then
    return
end
local save_id, string_warning = "sw_wildfires", "野火警告"
local default_data = {
    sw = "全部"
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local data_warn = {"关闭", "全部", "仅自燃"}
AddPrefabPostInit("smoke_plant", function(inst)
    if save_data.sw == "关闭" then
        return
    end
    inst:DoTaskInTime(0.1, function(inst)
        local ent = e_util:FindEnt(inst, nil, 0.0001, nil, {'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player'}, nil, nil,
            function(ent)
                return ent:HasTag("smolder")
            end)
        if not ent then
            return
        end
        if e_util:FindEnt(ent, "firesuppressor", TUNING.FIRE_DETECTOR_RANGE or 15, nil,
            {'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player', 'fueldepleted'}, nil, {"idle_off"}) then
            return
        end
        local name = e_util:GetPrefabName(ent.prefab)
        if not (name and TheWorld and TheWorld.state) then
            return
        end
        local threshold = TUNING.WILDFIRE_THRESHOLD or 80
        local content = " 被引燃！"
        local iswild
        if TheWorld.state.issummer and TheWorld.state.isday and type(TheWorld.state.temperature) == "number" and
            TheWorld.state.temperature >= threshold then
            content = " 发生自燃！"
            iswild = true
        end
        if save_data.sw == "全部" or (save_data.sw == "仅自燃" and iswild) then
            u_util:Say(string_warning, name .. content, "self", "红色")
        end
    end)
end)

local fn = m_util:AddBindShowScreen({
    title = string_warning,
    id = "hx_" .. save_id,
    data = {{
        id = "sw",
        label = "提示类型：",
        fn = fn_save("sw"),
        hover = "野火警告的提示类型",
        default = fn_get,
        type = "radio",
        data = t_util:IPairToIPair(data_warn, function(i)
            return {
                data = i,
                description = i
            }
        end)
    }},
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "天体后裔版本",
        fn = function()
            h_util:CreatePopupWithClose(nil, "该功能尚未有人定制，敬请期待...")
        end
    }}
})
m_util:AddBindConf(save_id, fn, nil, {string_warning, "firestaff_flamelash", "点击进入野火警告高级设置",
                                      true, fn, nil, -9996})
