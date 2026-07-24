local save_id = "gamefiler"
local save_data = s_mana:GetSettingLine(save_id, true)
local save__id = "colorfilter"
local save__data = s_mana:GetSettingLine(save__id, true)



local cube_default, bright_default, bright_start, bright_end = "bright", 1.3, 0.1, 4 
local screen_data = {}

local function NullFunction()
end
local function SaveFunction(meta)
    t_util:Pairs(meta, function(key, value)
        save_data[key] = value and true or nil
    end)
    s_mana:SaveSettingLine(save_id, save_data)
end


local value_insanity, 
value_lunacy, 
value_sob, 
value_bright, mode_insanity, mode_lunacy = 0, 0, 0, 1, 1, 2

local dusk_data, day_data = {}, {}
AddComponentPostInit("ambientlighting", function(self, inst)
    local colors = t_util:GetRecur(c_util:GetFnEnv(self.GetVisualAmbientValue),
        "_overridecolour.currentcolourset.PHASE_COLOURS")
    if not colors then
        return print('无法改变滤镜颜色！请联系模组作者！')
    end

    t_util:Pairs(colors, function(cate, color)
        if not dusk_data[cate] then
            dusk_data[cate] = {}
            day_data[cate] = {}
        end
        local c_data = t_util:GetRecur(color, "dusk.colour")
        local d_data = t_util:GetRecur(color, "day.colour")
        if not c_data then
            return print('无法改变滤镜颜色！请联系模组作者！')
        end
        t_util:Pairs(c_data, function(k, v)
            dusk_data[cate][k] = v
        end)
        t_util:Pairs(d_data, function(k, v)
            day_data[cate][k] = v
        end)
    end)
end)

i_util:AddWorldActivatedFunc(function(world)
    local pcrfuncs = getmetatable(PostProcessor).__index
    local _SetColourCubeLerp = pcrfuncs.SetColourCubeLerp
    pcrfuncs.SetColourCubeLerp = function(u_data, mode, value, ...)
        local v = save_data.sanity
        if mode == mode_insanity then
            value_insanity = value
            value = v and value or 0
        elseif mode == mode_lunacy then
            value_lunacy = value
            value = v and value or 0
        end

        return _SetColourCubeLerp(u_data, mode, value, ...)
    end

    local _SetOverlayBlend = pcrfuncs.SetOverlayBlend
    pcrfuncs.SetOverlayBlend = function(u_data, level, ...)
        value_sob = level
        return _SetOverlayBlend(u_data, save_data.sanity and level or 0, ...)
    end

    local function SanityFn(open)
        save_data.sanity = open
        _SetColourCubeLerp(PostProcessor, mode_insanity, open and value_insanity or 0)
        _SetColourCubeLerp(PostProcessor, mode_lunacy, open and value_lunacy or 0)
        _SetOverlayBlend(PostProcessor, open and value_sob or 0)
        PostProcessor:SetDistortionEnabled(open and true or false) 
    end
    SanityFn(save_data.sanity)

    table.insert(screen_data, 1, {
        id = "sanity",
        label = "精神滤镜",
        fn = function(show)
            SanityFn(show)
            SaveFunction({
                sanity = show
            })
        end,
        hover = "理智/启蒙值 变化的滤镜"
    })

    local cube_ori = type(save__data.now) == "nil" and false or save__data.now == cube_default

    local data_cc = {}
    local _SetColourCubeData = pcrfuncs.SetColourCubeData
    pcrfuncs.SetColourCubeData = function(u_data, mode, tex_old, tex_new, ...)
        data_cc[mode] = {
            tex_old = tex_old, 
            tex_new = tex_new,
            meta = ...
        }
        if cube_ori then
            return _SetColourCubeData(u_data, mode, tex_old, tex_new, ...)
        end
    end

    local data_cube = require "data/colorcube"

    local function ChangeCube(id)
        if id == "default" then
            cube_ori = true
            t_util:Pairs(data_cc, function(mode, data)
                _SetColourCubeData(PostProcessor, mode, data.tex_new, data.tex_new, data.meta)
            end)
        else
            id = id or cube_default
            cube_ori = false
            local cube = data_cube[id] and data_cube[id].cube
            if not cube then
                return
            end
            t_util:Pairs(data_cc, function(mode, data)
                _SetColourCubeData(PostProcessor, mode, cube, cube, data.meta)
            end)
            for i = 0, 2 do
                _SetColourCubeData(PostProcessor, i, cube, cube)
            end
        end
    end
    ChangeCube(save__data.now)

    local function setbtns(btns, id, bool)
        local btn = btns[id]
        if btn then
            btn.uiSwitch(bool)
        end
    end

    local function fn_cube(btns, id)
        t_util:Pairs(data_cube, function(id)
            setbtns(btns, id, false)
        end)
        setbtns(btns, id, true)
        
        ChangeCube(id)
        
        s_mana:SaveSettingLine(save__id, save__data, {
            now = id
        })
    end

    local function ChangeDusk(state)
        local fn = t_util:GetRecur(world, "components.ambientlighting.GetVisualAmbientValue")
        if not fn then
            return
        end
        local colors = t_util:GetRecur(c_util:GetFnEnv(fn), "_overridecolour.currentcolourset.PHASE_COLOURS")
        if not colors then
            return
        end
        t_util:Pairs(colors, function(cate, color)
            
            local lt = state and day_data[cate] or dusk_data[cate]
            if not lt then
                return
            end
            t_util:Pairs(lt, function(k, v)
                color.dusk.colour[k] = v
            end)
        end)
    end
    if type(save__data.dusk) == "nil" or save__data.dusk then
        ChangeDusk(true)
    end

    local function fn_dusk(state)
        ChangeDusk(state)
        s_mana:SaveSettingLine(save__id, save__data, {
            dusk = state
        })
    end

    local function GetFilterData()
        local filter_data = t_util:PairToIPair(data_cube, function(id, data)
            return {
                id = id,
                label = data.label .. "滤镜",
                fn = function(_, btns)
                    fn_cube(btns, id)
                end,
                hover = data.hover,
                default = id == cube_default and type(save__data.now) == "nil" or save__data.now == id,
                priority = data.priority or 0,
                notload = true 
            }
        end)
        local radiodata = {}
        table.insert(filter_data, {
            id = "dusk",
            label = "黄昏锁",
            hover = "【注意：开关此功能在进入下个阶段时才能生效】\n启用黄昏锁将会把黄昏亮度修改为白天的亮度",
            default = function()
                return type(save__data.dusk) == "nil" and true or save__data.dusk
            end,
            priority = 199,
            fn = fn_dusk
        })
        t_util:SortIPair(filter_data)
        return filter_data
    end

    local function filter_fn()
        m_util:PopShowScreen()
        TheFrontEnd:PushScreen(require("screens/huxi/showscreen")({
            title = "画面渲染",
            id = "filter",
            data = GetFilterData()
        }))
    end
    table.insert(screen_data, 1, {
        id = "filter", 
        label = "四季滤镜",
        fn = filter_fn,
        hover = "选择任意滤镜风格！",
        default = true
    })
end)


m_util:AddBindShowScreen("sw_beauti", "游戏滤镜", "butter", "实时修改游戏内各种滤镜", {
    title = "游戏滤镜",
    id = save_id,
    data = screen_data,
    default = function(id)
        return save_data[id] and true or false
    end,
    icon = {{
        id = "bilibili",
        prefab = "bilibili",
        hover = "教程演示",
        fn = function()
            VisitURL("https://www.bilibili.com/video/BV1eWoSBuExa/", true)
        end
    }}
}, nil, 9995)



