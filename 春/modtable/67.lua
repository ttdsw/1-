local save_id, map_str = "map_wormhole", "虫洞标记"
local default_data = {
    sw = true,
    addcolor = true,
    addtext = true,
    scale = 35
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local prefabs = require("data/mapicons").wormhole_data
local map_data = {}
local iscave
local function GetIcon(num)
    return iscave and "tentacle_pillar_" .. num or "wormhole_" .. num
end

local Colors = {"红色", "呼吸橙", "金黄色", "绿色", "呼吸蓝", "亮蓝色", "呼吸紫", "蓝色",
                "呼吸白"}
local function ChanWormhole(inst)
    local id = e_util:GetPosID(inst)
    if not id then
        return
    end
    local num = map_data[id] and map_data[id].num
    if num then
        
        h_util.SetAddColor(inst, save_data.sw and save_data.addcolor and Colors[num])
        
        h_util:AddText(inst, save_data.sw and save_data.addtext and num, nil, nil, nil, Colors[num])
    end
end

Mod_ShroomMilk.Func.GetWormholeData = function(inst)
    local id = e_util:GetPosID(inst)
    local num = id and map_data[id] and map_data[id].num
    if num then
        return save_data.sw and {
            num = num,
            icon = GetIcon(num),
            rgb = save_data.addcolor and Colors[num]
        }
    end
end

t_util:IPairs(prefabs, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0.5, ChanWormhole)
    end)
end)
local function ChanWormholes()
    t_util:IPairs(e_util:FindEnts(nil, prefabs), ChanWormhole)
end
local function ClearWormholes()
    
    t_util:Pairs(map_data, function(k)
        map_data[k] = nil
    end)
    
    local color, text = save_data.addcolor, save_data.text
    save_data.addcolor = false
    save_data.addtext = false
    ChanWormholes()
    save_data.addcolor, save_data.addtext = color, text
    
    local saver = m_util:GetSaver()
    if saver then
        saver:ClearHMap(save_id)
    end
end
i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    iscave = world:HasTag("cave")
    saver:RegHMap(save_id, map_str, "是否显示 " .. map_str .. " 的图标", function()
        return save_data.sw
    end, function(show)
        fn_save("sw")(show)
        if world.ismastersim then
            t_util:Pairs(Ents, function(id, ent)
                if table.contains(prefabs, ent.prefab) then
                    ChanWormhole(ent)
                end
            end)
        else
            ChanWormholes()
        end
    end, {
        screen_data = {{
            id = "addcolor",
            label = "地面虫洞染色",
            fn = function(v)
                fn_save("addcolor")(v)
                ChanWormholes()
            end,
            hover = "是否给地面上的虫洞染色",
            default = fn_get
        }, {
            id = "addtext",
            label = "虫洞标记数字",
            fn = function(v)
                fn_save("addtext")(v)
                ChanWormholes()
            end,
            hover = "是否给地面上的虫洞标记数字",
            default = fn_get
        }, {
            id = "delete",
            label = "删除虫洞标记",
            fn = function()
                h_util:CreatePopupWithClose("警告", "你确定要删除掉所有虫洞标记吗？", {{
                    text = "取消"
                }, {
                    text = "确认删除",
                    cb = ClearWormholes
                }})
            end,
            hover = "危险操作",
            type = "textbtn",
            default = "点击清理"
        }, {
            id = "scale",
            label = "虫洞图标大小：",
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
        }},
        scale = save_data.scale * 0.1 
    })
    
    map_data = saver:GetMap(save_id, true)
    
    t_util:Pairs(map_data, function(_, info)
        saver:AddHMap(save_id, {
            x = info.x,
            z = info.z,
            icon = GetIcon(info.num)
        })
    end)
end)
local function GetNearWormhole()
    return e_util:FindEnt(nil, prefabs, 4)
end
AddPrefabPostInit("player_classified", function(pc)
    pc:ListenForEvent("wormholetraveldirty", function(pc)
        
        local wormhole_in = GetNearWormhole()
        local id_in = e_util:GetPosID(wormhole_in)
        if not id_in or map_data[id_in] then
            return
        end
        local x_in, _, z_in = wormhole_in.Transform:GetWorldPosition()
        
        local num = 1
        t_util:Pairs(map_data, function(_, info)
            if info.num >= num then
                num = info.num + 1
            end
        end)
        if num > #Colors then
            return
        end
        
        e_util:WaitToDo(pc, 0.5, 10, function()
            local wormhole = GetNearWormhole()
            return wormhole and wormhole ~= wormhole_in and wormhole
        end, function(wormhole_out)
            local id_out = e_util:GetPosID(wormhole_out)
            if not id_out or map_data[id_out] then
                return
            end
            local x_out, _, z_out = wormhole_out.Transform:GetWorldPosition()
            
            map_data[id_in] = {
                x = x_in,
                z = z_in,
                num = num
            }
            map_data[id_out] = {
                x = x_out,
                z = z_out,
                num = num
            }
            
            ChanWormhole(wormhole_in)
            ChanWormhole(wormhole_out)
            
            local saver = m_util:GetSaver()
            if saver then
                saver:AddHMap(save_id, {
                    x = x_in,
                    z = z_in,
                    icon = GetIcon(num)
                }, true)
                saver:AddHMap(save_id, {
                    x = x_out,
                    z = z_out,
                    icon = GetIcon(num)
                }, true)
            end
        end)
    end)
end)
