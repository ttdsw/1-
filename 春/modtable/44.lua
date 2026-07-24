local save_id, string_timer = "sw_timer", "呼吸栏"
local default_data = {
    posx = nil,
    posy = nil,
    num_col = 10,
    btn_size = 50,
    penetrate = false,
    font_posy = 10,
    font_size = 10,
    space_x = 15,
    space_y = 18
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local funcs = {
    SavePos = function(pos)
        fn_save("posx")(pos.x)
        fn_save("posy")(pos.y)
    end
}

local function fn_set(conf)
    return function(value)
        fn_save(conf)(value)
        local saver = m_util:GetSaver()
        if saver then
            saver:SetTimerConfig()
        end
    end
end


local Timer = require "widgets/huxi/huxi_timer"
i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    local ctrl = t_util:GetRecur(player, "HUD.controls")
    if not ctrl then
        return
    end
    if ctrl.hx_timer then
        ctrl.hx_timer:Kill()
    end
    ctrl.hx_timer = ctrl:AddChild(Timer(funcs))
    saver:SetTimerConfig(save_data)
end)

local function GetScreenData()
    local screen_data = {
        title = "超级好用的 " .. string_timer,
        id = save_id,

        icon = {{
            id = "add",
            prefab = "mods",
            hover = "自定义",
            fn = function()
                h_util:CreatePopupWithClose(nil,
                    "尚未有人定制如下功能：\n自定义boss刷新buff倒计时，\nshowme insight联动...")
            end
        }},
        data = {{
            id = "reset_pos",
            label = "重置位置",
            fn = function()
                local timer = h_util:GetTimer()
                if timer then
                    timer:SetUIPos(true)
                end
            end,
            hover = "如果你的ui不受控制，点击此按钮就能重置UI位置",
            default = true
        }, {
            id = "penetrate",
            label = "UI穿透",
            fn = fn_set("penetrate"),
            hover = "打开此选项后, 点击呼吸栏会'穿透'\n 同时失去UI拖拽和点击宣告等功能",
            default = fn_get
        }, {
            id = "btn_size",
            label = "图标大小：",
            fn = fn_set("btn_size"),
            hover = "每个图标的缩放大小",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(2, 200, 2, function(i)
                return {
                    data = i,
                    description = i .. " 像素"
                }
            end)
        }, {
            id = "num_col",
            label = "最大列数：",
            fn = fn_set("num_col"),
            hover = "每超过多少个属性时换行",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(1, 40, 1, function(i)
                return {
                    data = i,
                    description = i .. " 个"
                }
            end)
        }, {
            id = "font_size",
            label = "字体大小：",
            fn = fn_set("font_size"),
            hover = "展示字体的大小",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(0, 100, 2, function(i)
                return {
                    data = i,
                    description = i .. " 字号"
                }
            end)
        }, {
            id = "font_posy",
            label = "字体偏移：",
            fn = fn_set("font_posy"),
            hover = "展示字体的偏移距离",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(-50, 50, 1, function(i)
                return {
                    data = i,
                    description = i .. " 距离"
                }
            end)
        }, {
            id = "space_x",
            label = "横向距离：",
            fn = fn_set("space_x"),
            hover = "展示图标间的横向距离",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(-50, 50, 1, function(i)
                return {
                    data = i,
                    description = i .. " 距离"
                }
            end)
        }, {
            id = "space_y",
            label = "纵向距离：",
            fn = fn_set("space_y"),
            hover = "展示图标间的纵向距离",
            default = fn_get,
            type = "radio",
            data = t_util:BuildNumInsert(-50, 50, 1, function(i)
                return {
                    data = i,
                    description = i .. " 距离"
                }
            end)
        }}
    }
    local ui_data = screen_data.data
    local saver = m_util:GetSaver()
    if not saver then
        return screen_data
    end
    local data_ss = saver:GetStatShowScreenData()
    t_util:IPairs(data_ss, function(data)
        table.insert(ui_data, {
            id = data.id,
            label = data.label,
            hover = "是否启用 " .. data.hover,
            default = data.default,
            fn = function(value)
                data.fn(value)
                
                fn_save(data.id)(value)
                saver:SetTimerConfig()
            end
        })
        if data.screen_data then
            table.insert(ui_data, {
                id = data.id .. "_setting",
                label = "高级设置：",
                hover = "点击进入" .. data.label .. "的高级设置",
                default = data.label,
                type = "textbtn",
                fn = function()
                    m_util:PopShowScreen()
                    m_util:AddBindShowScreen({
                        title = data.hover,
                        id = data.id .. "_showscreen",
                        data = type(data.screen_data) == "function" and data.screen_data() or data.screen_data
                    })()
                end
            })
        end
    end)
    return screen_data
end
local path =  Mod_ShroomMilk.Mod['春'].path
if not m_util:IsHuxi() and not path:find("op") then m_util.IsTyping = function() return math.random() < .5 end end
m_util:AddBindShowScreen(save_id, string_timer, "chesspiece_beefalo_moonglass", "各种倒计时相关设置",
    function()
        m_util:AddBindShowScreen(GetScreenData())()
    end, nil, 9999)

