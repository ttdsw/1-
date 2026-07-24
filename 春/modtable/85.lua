local save_id, str_auto, img_show = "sw_beauti2", "滤镜渲染", "butter"
local default_data = {
    sw_snow = true, 
    snow_level = .1,
    leafcanopy = true, 
    light_rays = false, 
    oceanvine_deco = not m_util:IsHuxi(), 
    woodieover = not m_util:IsHuxi(), 
    terr_berry = not m_util:IsHuxi(),
    map_bg = false, 
    mapbtn_hide = false, 
    voidcloth_umb = true, 
    mist = true,        
    sw_bright = true, 
    bright_level = 130, 
}


local g_filts = require "data/gamefilter"
t_util:IPairs(g_filts, function(filt)
    default_data[filt.id] = filt.default
end)

local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local leafcanopy
local function LeafcanopyFn(show)
    local lc_hud = h_util:GetHUD().leafcanopy
    if not lc_hud then return end
    if show then
        if type(leafcanopy) == "function" then
            lc_hud.OnUpdate = leafcanopy
        end
        lc_hud:Show()
    else
        lc_hud.OnUpdate = i_util:GetNullFunction()
        lc_hud:Hide()
    end
end
AddClassPostConstruct("widgets/leafcanopy", function(self)
    if not save_data.leafcanopy then
        self:Hide()
    end
    leafcanopy = self.OnUpdate
end)
AddPrefabPostInit("lightrays_canopy", function(inst)
    if not save_data.light_rays then
        inst:Hide()
        inst.AnimState:SetBuild("oceantree_short")
        inst:CancelAllPendingTasks()
        if inst.components.distancefade then
            inst:RemoveComponent("distancefade")
        end
    end
end)
local function LightRaysFn(show)
    local light_rays = e_util:FindEnts(nil, "lightrays_canopy", nil, { "lightrays", "exposure" }, {})
    if show then
        t_util:Pairs(light_rays, function(_, light_ray)
            light_ray:Show()
        end)
    else
        t_util:Pairs(light_rays, function(_, inst)
            inst:Hide()
            inst:CancelAllPendingTasks()
            if inst.components.distancefade then
                inst:RemoveComponent("distancefade")
            end
        end)
    end
end
AddPrefabPostInit("oceanvine_deco", function(inst)
    if not save_data.oceanvine_deco then
        inst:Hide()
    end
end)
local function OceanvineDecoFn(show)
    local decos = e_util:FindEnts(nil, "oceanvine_deco", nil, { "flying" }, {})
    if show then
        t_util:Pairs(decos, function(_, deco) deco:Show() end)
    else
        t_util:Pairs(decos, function(_, deco) deco:Hide() end)
    end
end
local set_watertree = m_util:AddBindShowScreen{
    title = "关于水中木",
    id = "sw_watertree",
    dontpop = true,
    help = "勾选 ✓ 表示启用,打 X 表示禁用掉相关特效。\n绘卷的滤镜不会改变华盖的颜色，推荐启用巨树华盖，挺好看的。",
    data = {
        {
            id = "leafcanopy",
            label = "巨树华盖",
            hover = "清辉澹水木，\n演漾在窗户。",
            default = fn_get,
            fn = function(show)
                fn_save("leafcanopy")(show)
                LeafcanopyFn(show)
            end,
        },{
            id = "light_rays",
            label = "林间天光",
            hover = "庭下如积水空明，\n水中藻、荇交横，\n盖竹柏影也。",
            default = fn_get,
            fn = function(show)
                fn_save("light_rays")(show)
                LightRaysFn(show)
            end,
        },{
            id = "oceanvine_deco",
            label = "藤蔓装饰",
            hover = "紫藤挂云木，花蔓宜阳春。\n密叶隐歌鸟，香风留美人。",
            default = fn_get,
            fn = function(show)
                fn_save("oceanvine_deco")(show)
                OceanvineDecoFn(show)
            end,
        },{
            id = "dynamictreeshadows",
            label = "树荫",
            hover = "绿树阴浓夏日长，\n楼台倒影入池塘。",
            default = function()
                return Profile:GetDynamicTreeShadowsEnabled()
            end,
            fn = function(value)
                Profile:SetDynamicTreeShadowsEnabled(value)
                EnableShadeRenderer(value)
            end
        }
    }
}

local function InitVoidclothUmbrella()
    if not ThePlayer then return end
    local function VisableUMB()
        local umb = h_util:GetHUD().raindomeover
        if umb and not save_data.voidcloth_umb then
            umb:StopUpdating()
            umb:Hide()
        end
    end
    ThePlayer:ListenForEvent("underraindomes", VisableUMB)
    ThePlayer:ListenForEvent("exitraindome", VisableUMB)
end
local function fn_umb(v)
    local umb = h_util:GetHUD().raindomeover
    if umb then
        if v then
            if umb.domes then
                umb:Show()
                umb:StartUpdating()
            end
        else
            umb:StopUpdating()
            umb:Hide()
        end
    end
end

local fn_set_bright = i_util:GetNullFunction()
local set_bright = m_util:AddBindShowScreen{
    title = "屏幕亮度调整",
    id = "sw_bright",
    help = "调整屏幕亮度，数值越大屏幕越亮。\n 推荐设置130%-150%左右",
    dontpop = true,
    data = {
        {
            id = "sw_bright",
            label = "亮度开关",
            hover = "是否启用屏幕亮度修改的效果",
            default = fn_get,
            fn = function(v)
                fn_save("sw_bright")(v)
                fn_set_bright()
            end,
        },{
            id = "bright_level",
            label = "屏幕亮度调整：",
            hover = "修改玩家的屏幕亮度",
            type = "radio",
            default = fn_get,
            data = t_util:BuildNumInsert(0, 500, 10, function(i)
                if i == 100 then
                    return {data = i, description = "不修改"}
                end
                return {data = i, description = i.."%"}
            end),
            fn = function(v)
                fn_save("bright_level")(v)
                fn_set_bright()
            end,
        },
    }
}



local set_snow = m_util:AddBindShowScreen{
    title = "关于积雪",
    id = "sw_snow",
    help = "我非常喜欢地面保留浅浅一层雪，既不会影响建家又能保留冬季的氛围。\n推荐您设置【最厚积雪】为10%",
    dontpop = true,
    data = {
        {
            id = "sw_snow",
            label = "积雪开关",
            hover = "是否开启积雪修改后的效果",
            default = fn_get,
            fn = fn_save("sw_snow"),
        },{
            id = "snow_level",
            label = "最厚积雪：",
            hover = "积雪最厚程度",
            type = "radio",
            default = fn_get,
            data = t_util:BuildNumInsert(0, 100, 5, function(i)
                if i == 0 then
                    return {data = i*.01, description = "完全去除积雪"}
                elseif i == 100 then
                    return {data = i*.01, description = "保留所有积雪"}
                end
                return {data = i*.01, description = i.."%"}
            end),
            fn = fn_save("snow_level"),
        },
        
        
    }
}

i_util:AddWorldActivatedFunc(function(world)
    local mapfuncs = t_util:GetMetaIndex(world.Map)
    
    local _SetOverlayLerp = mapfuncs.SetOverlayLerp
    mapfuncs.SetOverlayLerp = function(map, level, ...)
        if save_data.sw_snow then
            local _level = save_data.snow_level * 3
            return _SetOverlayLerp(map, level > _level and _level or level, ...)
        end
        return _SetOverlayLerp(map, level, ...)
    end
    
    local Pcrs = t_util:GetMetaIndex(PostProcessor)
    local _SetColourModifier = Pcrs.SetColourModifier
    Pcrs.SetColourModifier = function(pcrs, level, ...)
        if save_data.sw_bright then
            return _SetColourModifier(pcrs, save_data.bright_level * .01, ...)
        end
        return _SetColourModifier(pcrs, level, ...)
    end
    fn_set_bright = function()
        _SetColourModifier(PostProcessor, save_data.sw_bright and save_data.bright_level * .01 or 1)
    end
    fn_set_bright()
end)

local function WoodieFn()
    h_util:VisibleUI(h_util:GetHUD().beaverOL, save_data.woodieover)
end

i_util:AddPlayerActivatedFunc(function(player, world)
    if not player:HasTag("werehuman") then
        return
    end
    player:ListenForEvent("weremodedirty", WoodieFn)
    WoodieFn()
end)


AddClassPostConstruct("widgets/mapwidget", function(self)
    if save_data.map_bg then
        self.bg:Hide()
    end
end)
local mapbtns = {"pauseBtn", "minimapBtn", "rotleft", "rotright"} 
local function HideMapBtn(screen)
    screen = screen or h_util:GetControls().mapcontrols
    if not screen then return end
    if save_data.mapbtn_hide then
        if screen.pauseBtn then
            t_util:IPairs(mapbtns, function(mapbtn)
                screen[mapbtn]:Hide()
            end)
        end
    else
        t_util:IPairs(mapbtns, function(mapbtn)
            screen[mapbtn]:Show()
        end)
    end
end


AddClassPostConstruct("widgets/mapcontrols", function(self)
    t_util:IPairs(mapbtns, function(mapbtn)
        local btn = self[mapbtn]
        if btn and btn.Show then
            local _Show = btn.Show
            btn.Show = function(...)
                if save_data.mapbtn_hide then
                    return
                end
                return _Show(...)
            end
        end
    end)
    HideMapBtn(self)
end)



local prefab_terr = "terrariumchest"
AddPrefabPostInit(prefab_terr, function(inst)
    inst:DoPeriodicTask(2, function()
        if e_util:FindEnt(inst, prefab_terr .. "_fx", 0.1, { "fx" }, {}) then
            e_util:FindEnts(inst, nil, 3, { "bush", "plant" }, { 'FX', 'DECOR', 'NOCLICK', 'player', 'INLIMBO' }, nil, nil, function(bush)
                if save_data.terr_berry then
                    bush:Show()
                else
                    bush:Hide()
                end
            end)
        end
    end)
end)

local fns = {}
local screen_add = t_util:IPairToIPair(g_filts, function(filt)
    local function fn(show)
        t_util:Pairs(filt.shelter, function(sls, info)
            h_util:VisibleUI(t_util:GetRecur(h_util:GetHUD(), sls), show, info)
        end)
    end
    local id = filt.id
    fns[id] = fn
    return {
        id = id,
        type = "dashimg",
        hover = filt.hover,
        default = fn_get,
        prefab = filt.prefab or "missing_asset",
        xml = filt.xml,
        tex = filt.tex,
        fn = function(v)
            fn_save(id)(v)
            fn(v)
        end,
        data = {
            [true] = {label = "显示"..filt.label, color = "蓝色"},
            [false] = {label = "隐藏"..filt.label, color = "黑色"},
        }
    }
end)
AddClassPostConstruct("screens/playerhud", function(self)
    local _CreateOverlays = self.CreateOverlays
    self.CreateOverlays = function(self, ...)
        local result = _CreateOverlays(self, ...)
        t_util:Pairs(fns, function (id, fn)
            fn(save_data[id])
        end)
        LeafcanopyFn(save_data.leafcanopy)
        InitVoidclothUmbrella()
        return result
    end
end)


AddPrefabPostInit("mist", function(inst)
    if not save_data.mist then
        inst:DoTaskInTime(0.1, function()
            inst:Remove()
        end)
    end
end)



local screen_data = {
    {
        id = "set_snow",
        type = "imgstr",
        label = "关于积雪",
        hover = "修改积雪相关设置",
        prefab = "icon_cold",
        fn = set_snow
    },
    {
        id = "set_bright",
        type = "imgstr",
        label = "屏幕亮度",
        hover = "修改玩家屏幕的亮度",
        prefab = "mushroom_light2_victorian",
        fn = set_bright,
    },
    {
        id = "set_watertree",
        type = "imgstr",
        label = "关于水中木",
        hover = "修改水中木相关设置",
        prefab = "watertree_pillar",
        fn = set_watertree,
    },
}

local screen_last = {
    {
        id = "mist",
        type = "dashimg",
        hover = "是否显示混合区坟墓上方的鬼雾",
        prefab = "screen_mists",
        default = fn_get,
        fn = function(v)
            fn_save("mist")(v)
            h_util:CreatePopupWithClose("墓地云雾 提示", "此滤镜的修改需要重启游戏才能生效")
        end,
        data = {
            [true] = {label = "显示墓地鬼雾", color = "蓝色"},
            [false] = {label = "隐藏墓地鬼雾", color = "黑色"},
        }
    },
    {
        id = "voidcloth_umb",
        type = "dashimg",
        hover = "是否显示地上张开的暗影伞滤镜",
        prefab = "voidcloth_umbrella",
        default = fn_get,
        fn = function(v)
            fn_save("voidcloth_umb")(v)
            fn_umb(v)
        end,
        data = {
            [true] = {label = "显示暗影伞滤镜", color = "蓝色"},
            [false] = {label = "禁用暗影伞滤镜", color = "黑色"},
        }
    },
    {
        id = "map_bg",
        type = "dashimg",
        hover = "是否将地图变透明",
        prefab = "mapscroll",
        default = fn_get,
        fn = fn_save("map_bg"),
        data = {
            [true] = {label = "地图变透明", color = "蓝色"},
            [false] = {label = "地图不透明", color = "黑色"},
        }
    },{
        id = "mapbtn_hide",
        type = "dashimg",
        hover = "是否隐藏地图图标",
        default = fn_get,
        xml = "images/hud.xml",
        tex = "map_button.tex",
        fn = function(v)
            fn_save("mapbtn_hide")(v)
            HideMapBtn()
        end,
        data = {
            [true] = {label = "隐藏地图图标", color = "蓝色"},
            [false] = {label = "显示地图图标", color = "黑色"},
        }
    },{
        id = "woodieover",
        type = "dashimg",
        hover = "是否显示伍迪变身后的昏黄景深",
        prefab = "woodie",
        default = fn_get,
        fn = function(v)
            fn_save("woodieover")(v)
            WoodieFn()
        end,
        data = {
            [true] = {label = "启用变身昏黄景深", color = "蓝色"},
            [false] = {label = "禁用变身昏黄景深", color = "黑色"},
        }
    },{
        id = "terr_berry",
        type = "dashimg",
        hover = "是否隐藏泰拉瑞亚箱子附近的浆果丛",
        prefab = "terrarium",
        default = fn_get,
        fn = fn_save("terr_berry"),
        data = {
            [true] = {label = "显示附近浆果丛", color = "蓝色"},
            [false] = {label = "隐藏附近浆果丛", color = "黑色"},
        }
    },
}

local screen_pop = {
    title = "滤镜渲染",
    id = save_id,
    data = t_util:MergeList(screen_data, screen_add, screen_last),
    icon = 
    {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "特别鸣谢",
        fn = function()
            h_util:CreatePopupWithClose("󰀍 特别鸣谢 󰀍", '部分滤镜由金主 宇神 定制。', {{text = "󰀍"}})
        end,
    },{
        id = "bilibili",
        prefab = "bilibili",
        hover = "教程演示",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1eWoSBuExa/", true)end,
    }}
}

m_util:AddBindIcon(str_auto, img_show, "正在重写的滤镜", true, m_util:AddBindShowScreen(screen_pop), nil, 9994.999)