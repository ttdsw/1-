local save_id, map_str = "map_alter", "定位天体"
local default_data = {
    sw = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local prefabs = {"archive_resonator_base", "medal_resonator_base"}
local bases = {"moon_altar_astral_marker_1", "moon_altar_astral_marker_2"}
local fxes = {}
local pos_old, mark_show


local function SetIcon(pos)
    local saver = m_util:GetSaver()
    if not (pos and pos.x and pos.z and saver) then return end
    local info = {
        x = pos.x,
        z = pos.z,
        icon = "mark_y",
    }
    if pos_old then
        saver:ChanHMap(save_id, {
            x = pos_old.x,
            z = pos_old.z,
            icon = "mark_y",
        }, info)
    else
        saver:AddHMap(save_id, info, true)
    end
    pos_old = pos
end

local function SpawnMark(x, z)
    local mark = e_util:SpawnFx(map_str, "archive_resonator", "archive_resonator", "locating", h_util:GetWRGB("黄色"), 0.5)
    mark.Transform:SetPosition(x, 0, z)
    table.insert(fxes, mark)
    local func = Mod_ShroomMilk.Func.AddModIndicator
    local xml, tex, name = h_util:GetPrefabAsset("archive_resonator")
    if func and xml then
        func(mark, xml, tex, name, {fn_left = function(ui, target) ui:Kill() end}, {color = "黄色"})
    end
end

local function ClearMark()
    t_util:Pairs(fxes, function(id, fx)
        fx:Remove()
        fxes[id] = nil
    end)
end
local function fn_left()
    
    mark_show = true
    ClearMark()

    
    local arrows = e_util:FindEnts(nil, prefabs, nil, nil, {"huxi"})
    if #arrows < 2 then
        local str_popup = #arrows == 0 and
                              "定位标记不足, 请放置星象探测仪或寻宝装置\n需要一个屏幕的范围内有两个箭头标记" or
                              "定位标记不足, 请继续放置星象探测仪或寻宝装置\n需要一个屏幕的范围内有两个箭头标记"
        return h_util:CreatePopupWithClose(map_str .. "·提示", str_popup)
    end

    
    local a1, a2 = arrows[1], arrows[2]
    local r1, r2 = a1:GetRotation() + 90, a2:GetRotation() + 90
    local rad1, rad2 = -math.rad(r1), -math.rad(r2)
    local m1, m2 = math.tan(rad1), math.tan(rad2)
    if m1 == m2 then
        return h_util:CreatePopupWithClose(map_str .. "·提示",
            "两个定位标记平行，无法判断\n请重新放置星象探测仪或寻宝装置")
    end
    local x1, _, y1 = a1.Transform:GetWorldPosition()
    local x2, _, y2 = a2.Transform:GetWorldPosition()
    local c1 = y1 - m1 * x1
    local c2 = y2 - m2 * x2
    local x = (c2 - c1) / (m1 - m2)
    local z = m1 * x + c1
    
    SetIcon({x = x, z = z})
    SpawnMark(x, z)

    
    h_util:PlaySound("learn_map")
    local ctrl = h_util:GetControls()
    if ctrl.ShowMap then
        ctrl:ShowMap(Vector3(x, 0, z))
    end
end


i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegHMap(save_id, map_str, "该功能无法关闭...", function() return save_data.sw end, fn_save("sw"))
end)

local fn_right = m_util:AddBindShowScreen({
    title="定位天体 教程",
    id=save_id,
    data = {{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1yF27BuEBG/", true)end
    },
    }
})
m_util:AddBindConf(save_id, fn_left, fn_right, {map_str, "archive_resonator_item",
                                           STRINGS.LMB .. map_str..STRINGS.RMB.."教程演示", true,
                                           fn_left, fn_right, 5995})

t_util:IPairs(bases, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if mark_show then
            inst:DoTaskInTime(0.5, function(inst)
                local trans = e_util:IsValid(inst)
                if trans then
                    local x, _, z = trans:GetWorldPosition()
                    SpawnMark(x, z)
                end
            end)
        end
    end)
end)

AddPrefabPostInit("archive_resonator", function(inst)
    if mark_show then
        ClearMark()
    end
end)