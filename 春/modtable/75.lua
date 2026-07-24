if m_util:IsServer() then
    return
end

local animals = require "data/starfishes"
local hxname, hxprefab = "_starfish", "_hxprefab"


local save_id, string_show = "sw_starfish", "海星清远古"
local default_data = {
    show = m_util:IsHuxi(),
    scale = 0.4
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local icons,hxnames = {}, {}
local radius = 1.24

local directions = {  
    {0, 1}, 
    {1, 1}, 
    {1, 0}, 
    {-1, 1}, 
    {0, -1}, 
    {-1, -1}, 
    {-1, 0}, 
    {1, -1}, 
}  

t_util:Pairs(animals, function(prefab, animal)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0.5, function()
            if e_util:IsAnim(function(anim)
                return anim:match("idle") or anim:match("sleep")
            end, inst) then
                local pusher = m_util:GetPusher()
                if pusher then
                    pusher:RegNearStart(inst, function(x, z)
                        if not inst[hxname] then
                            local an = e_util:SpawnFx(hxname, animal.build, animal.bank, animal.anim, {0, 1, 0, 1}, save_data.scale)
                            if an then
                                inst[hxname] = an
                                an.Transform:SetPosition(x, 0, z)
                                table.insert(icons, an)
                                if not save_data.show then
                                    an:Hide()
                                end
                            end
                        end
                    end)
                end
            end
        end)
    end)
end)


local function fn()
    local pusher = m_util:GetPusher()
    if not pusher then
        return
    end


    local prefab_star = "dug_trap_starfish"
    local star = p_util:GetItemFromAll(prefab_star, nil, nil, "mouse")
    
    local fx = e_util:FindEnt(nil, nil, nil, {"huxi", "fx"}, {}, nil, nil, function(ent)
        return ent.hxname == hxname
    end)
    if not (star and fx) then
        h_util:CreatePopupWithClose(string_show.." · 提示",
                "请靠近刷新点并携带海星，再尝试此功能")
        return u_util:Say("没有海星或刷新标记")
    end

    local SetGeoCTRL = Mod_ShroomMilk.Func.SetGeoCTRL
    if SetGeoCTRL then
        SetGeoCTRL(not TheInput:IsKeyDown(KEY_CTRL))
    else
        u_util:Say("无法判断是否开启几何，推荐手动关闭几何或者使用绘卷的几何")
    end

    pusher:RegNowTask(function(player, pc)
        if d_util:TakeActiveItem(star) then
            u_util:Say("拿不起海星")
        else
            local item_active = p_util:GetActiveItem()
            local invitem = t_util:GetRecur(item_active, "replica.inventoryitem")
            if invitem then
                local pos_fx = fx:GetPosition()
                local xp, _, yp = pos_fx:Get()
                local pos = t_util:IGetElement(directions, function(dir)
                    local x, y = xp + dir[1], yp + dir[2]
                    local pos_new = c_util:GetIntersectPotRadiusPot(pos_fx, radius, Vector3(x, 0, y))
                    return invitem:CanDeploy(pos_new, nil, player) and pos_new
                end)
                if pos then
                    p_util:Click(pos, true)
                else
                    u_util:Say("该生成点无法放置，请清理周围")
                end
            else
                u_util:Say("功能异常，请联系开发者修复")
            end
        end
        return true
    end)
end

local screen_data = {{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()VisitURL("https://www.xiaohongshu.com/explore/69136d9a000000000402a22e?app_platform=android&ignoreEngage=true&app_version=8.42.0&share_from_user_hidden=true&xsec_source=app_share&type=video&xsec_token=CBxEH_jtmnYdO2PBfK68PNXBIshDTKrNf9l9SvdkAb12w=&author_share=1&xhsshare=QQ&shareRedId=N0wzRTpJR042NzUyOTgwNjY0OThHPEg_&apptime=1762881049&share_id=ebc7b63dd6514f49a95d65e589856336", true)end
    },{
        id = "show",
        label = "刷新点显示",
        hover = "默认是否展示刷新点",
        default = fn_get,
        fn = function(show)
            fn_save("show")(show)
            t_util:IPairs(icons, function(an)
                if an:IsValid() then
                    if show then
                        an:Show()
                    else
                        an:Hide()
                    end
                end
            end)
        end,
    },{
        id = "scale",
        label = "标记大小：",
        hover = "刷新点标记的大小",
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(0.1, 2, 0.05, function(i)
            return {data = i, description = i}
        end),
        fn = function(scale)
            fn_save("scale")(scale)
            t_util:IPairs(icons, function(an)
                if an:IsValid() then
                    an.AnimState:SetScale(scale, scale, scale)
                end
            end)
        end
    }
}


local func_right = m_util:AddBindShowScreen({
    title = string_show,
    id = "hx_" .. save_id,
    data = screen_data,            icon = 
    {{
        id = "add",
        prefab = "mods",
        hover = "点位存储",
        fn = function()
            h_util:CreatePopupWithClose(nil, "尚未有人定制此功能，敬请期待...")
        end,
    }},
})


m_util:AddBindConf(save_id, fn, nil,
    {string_show, "dug_trap_starfish", STRINGS.LMB .. '种植海星' .. STRINGS.RMB .. '高级设置', true, fn,
     func_right, 7991})
