local default_data = {
    sw = false,
    scale = 0.7,
    font = HEADERFONT,
    keytweak = {
        [1] = {"KEY_LCTRL", "KEY_SPACE"},
        [2] = {"KEY_LSHIFT", "KEY_A", "KEY_S", "KEY_D", "KEY_F"},
        [3] = {"KEY_LALT", "KEY_Q", "KEY_W", "KEY_E", "KEY_R"}
    },
    color1 = "白色",
    color2 = "白色",
    color3 = "白色",
    init_x = -20,
    init_y = 25
}
local save_id, str_show = "sw__keytweak", "键位提示+"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local KT = require "widgets/huxi/hx__keytweak"
local k_util = require "util/keybind"
local PopupDialogScreen = require "screens/redux/popupdialog"
local V_data = require("data/valuetable")
local kid = "HX_KT"
local KeyBind = {}
local funcs_kt = {}
local function AddKeyBind(keycode, up, func)
    local press = up and "onkeyup" or "onkeydown"
    local ipt = TheInput[press]
    local _func = KeyBind[keycode]
    if _func then
        m_util:RemoveHandler(ipt, keycode, _func)
        KeyBind[keycode] = nil
    end
    if func then
        ipt:AddEventHandler(keycode, func)
        KeyBind[keycode] = func
    end
end
local function GetUID(keycode)
    return kid .. keycode
end

local function GetKT()
    return h_util:GetControls()[kid]
end
local function GetKT_BTN(keycode)
    local kt = GetKT()
    return h_util:IsValid(kt) and kt[GetUID(keycode)]
end

local function BindKT()
    local b_data = {}
    t_util:IPairs(save_data.keytweak, function(line)
        t_util:IPairs(line, function(key_str)
            local keycode = k_util:GetKeyCode(key_str)
            if keycode then
                table.insert(b_data, {
                    code = keycode,
                    down = function()
                        local btn = GetKT_BTN(keycode)
                        if btn then
                            btn.func_press(true)
                        end
                    end,
                    up = function()
                        local btn = GetKT_BTN(keycode)
                        if btn then
                            btn.func_press()
                        end
                    end
                })
            else
                m_util:print("非法保存！", key_str)
            end
        end)
    end)
    t_util:IPairs(b_data, function(data)
        AddKeyBind(data.code)
        AddKeyBind(data.code, true)
    end)
    if not save_data.sw then
        return
    end
    t_util:IPairs(b_data, function(data)
        AddKeyBind(data.code, nil, data.down)
        AddKeyBind(data.code, true, data.up)
    end)
end

local function ReMakeKT(screen)
    local kt = GetKT()
    if h_util:IsValid(kt) then
        kt:Kill()
    end
    if save_data.sw then
        screen = screen or h_util:GetControls()
        if h_util:IsValid(screen) then
            screen[kid] = screen:AddChild(KT(save_data, funcs_kt))
            BindKT()
        end
    end
end

local function fn_set(id)
    return function(val)
        fn_save(id)(val)
        ReMakeKT()
    end
end

local function fn_left()
    fn_save("sw")(not save_data.sw)
    local sw = save_data.sw
    u_util:Say(str_show, sw)
    ReMakeKT()
end
local str_default_add, str_default_remove = "点击录入键位", "尚未录入键位"
local function fn_text_all(id)
    local function printtext(i)
        local str = ""
        t_util:IPairs(save_data.keytweak[i], function(keystr)
            local show_str = k_util:GetShow(keystr)
            show_str = show_str == " " and "SPACE" or show_str
            if #str < 20 then
                str = str .. show_str .. ","
            end
        end)
        return str == "" and str_default_add or str:sub(1, -2)
    end
    local num = tonumber(id:sub(-1))
    return num and printtext(#save_data.keytweak - num + 1) or str_default_add
end

local function fn_text_last(id)
    local function printtext(i)
        local dict = save_data.keytweak[i]
        local show_str = k_util:GetShow(dict[#dict])
        return show_str and (show_str == " " and "SPACE" or show_str) or str_default_remove
    end
    local num = tonumber(id:sub(-1))
    return num and printtext(#save_data.keytweak - num + 1) or str_default_remove
end
local function PopFunc()
    TheFrontEnd:PopScreen()
end

local function fn_bind(id)
    local _num = tonumber(id:sub(-1))
    local num = _num and #save_data.keytweak - _num + 1
    return num and function(text, ui, screen_data)
        local popup = PopupDialogScreen(str_show, "请按下键盘按键为本行录入键位!", {{
            text = "算了",
            cb = PopFunc
        }})
        popup.OnRawKey = function(_, keycode, down)
            if down then
                return
            end
            local keystr = k_util:GetKeyStr(keycode)
            if keystr then
                
                if t_util:IGetElement(save_data.keytweak, function(line)
                    return t_util:IGetElement(line, function(_keystr)
                        return _keystr == keystr
                    end)
                end) then
                    popup.dialog.body:SetString("按键 " .. keystr .. " 已经绑定过了，换一个吧。")
                else
                    
                    table.insert(save_data.keytweak[num], keystr)
                    fn_save()
                    
                    ReMakeKT()
                    ui["add_" .. _num].uiSwitch(fn_text_all("add_" .. _num))
                    ui["remove_" .. _num].uiSwitch(fn_text_last("remove_" .. _num))
                    h_util:PlaySound("click_move")
                    PopFunc()
                    return
                end
            else
                popup.dialog.body:SetString("这个按键不行呦，换一个嘛。")
                m_util:print(keycode)
            end
            h_util:PlaySound("click_negative")
        end
        TheFrontEnd:PushScreen(popup)
    end or h_util.error
end

local function fn_remove(id)
    local _num = tonumber(id:sub(-1))
    local num = _num and #save_data.keytweak - _num + 1
    return num and function(text, ui, screen_data)
        local body_text = "您确定要移除键位 " .. text .. " 吗？"
        local btns = {{
            text = h_util.no
        }, {
            text = h_util.yes,
            cb = function()
                table.remove(save_data.keytweak[num])
                fn_save()
                ReMakeKT()
                ui["add_" .. _num].uiSwitch(fn_text_all("add_" .. _num))
                ui["remove_" .. _num].uiSwitch(fn_text_last("remove_" .. _num))
            end
        }}
        if text == str_default_remove then
            body_text = "没有可以移除的键位！"
            btns = {{
                text = h_util.ok
            }}
        end
        h_util:CreatePopupWithClose(str_show, body_text, btns)
    end or h_util.error
end

local function fn_reset()
    h_util:CreatePopupWithClose(str_show, "您确定要恢复默认键位吗？", {{
        text = h_util.no
    }, {
        text = h_util.yes,
        cb = function()
            h_util:PlaySound("learn_map")
            t_util:Pairs(save_data.keytweak, function(col, line)
                save_data.keytweak[col] = {}
                t_util:IPairs(default_data.keytweak[col], function(value)
                    table.insert(save_data.keytweak[col], value)
                end)
            end)
            fn_save()
            ReMakeKT()
            PopFunc()
        end
    }})
end
local screen_data = {{
    id = "add_1",
    label = "第一行录入：",
    hover = "点击增加新按钮",
    default = fn_text_all,
    fn = fn_bind("add_1"),
    type = "textbtn"
}, {
    id = "remove_1",
    label = "第一行移除：",
    hover = "点击移除末尾按钮",
    default = fn_text_last,
    fn = fn_remove("remove_1"),
    type = "textbtn"
}, {
    id = "add_2",
    label = "第二行录入：",
    hover = "点击增加新按钮",
    default = fn_text_all,
    fn = fn_bind("add_2"),
    type = "textbtn"
}, {
    id = "remove_2",
    label = "第二行移除：",
    hover = "点击移除末尾按钮",
    default = fn_text_last,
    fn = fn_remove("remove_2"),
    type = "textbtn"
}, {
    id = "add_3",
    label = "第三行录入：",
    hover = "点击增加新按钮",
    default = fn_text_all,
    fn = fn_bind("add_3"),
    type = "textbtn"
}, {
    id = "remove_3",
    label = "第三行移除：",
    hover = "点击移除末尾按钮",
    default = fn_text_last,
    fn = fn_remove("remove_3"),
    type = "textbtn"
}, {
    id = "sw",
    label = "键位显示",
    hover = "开启或关闭键位显示",
    default = fn_get,
    fn = function(value)
        fn_save("sw")(value)
        ReMakeKT()
    end
}, {
    id = "reset",
    label = "恢复默认键位",
    hover = "点击恢复默认键位",
    default = true,
    fn = fn_reset
}, {
    id = "scale",
    label = "缩放:",
    hover = "对UI大小调整\n默认 " .. default_data.scale,
    default = fn_get,
    type = "radio",
    data = t_util:BuildNumInsert(0.1, 4, 0.05, function(i)
        return {
            data = i,
            description = i .. " 倍"
        }
    end),
    fn = fn_set("scale")
}, {
    id = "font",
    label = "字体:",
    hover = "选择你喜欢的字体",
    default = fn_get,
    type = "radio",
    data = V_data.font_datatable,
    fn = fn_set("font")
}, {
    id = "color1",
    label = "抬起颜色：",
    hover = "抬起按键后显示的颜色",
    default = fn_get,
    type = "radio",
    fn = fn_set("color1"),
    data = V_data.RGB_datatable
}, {
    id = "color2",
    label = "按下颜色：",
    hover = "按下按键后显示和黄色叠加后的颜色\n这里是颜色叠加，不是设定对应颜色",
    default = fn_get,
    type = "radio",
    fn = fn_set("color2"),
    data = V_data.RGB_datatable
}, {
    id = "init_x",
    label = "相对横坐标：",
    hover = "默认 " .. default_data.init_x .. " 像素",
    default = fn_get,
    type = "radio",
    fn = fn_set("init_x"),
    data = t_util:BuildNumInsert(-1000, 2000, 5, function(i)
        return {
            data = i,
            description = i .. " 像素"
        }
    end)
}, {
    id = "init_y",
    label = "相对纵坐标：",
    hover = "默认 " .. default_data.init_y .. " 像素",
    default = fn_get,
    type = "radio",
    fn = fn_set("init_y"),
    data = t_util:BuildNumInsert(-1000, 2000, 5, function(i)
        return {
            data = i,
            description = i .. " 像素"
        }
    end)
}, {
    id = "color3",
    label = "字体颜色：",
    hover = "字体的颜色",
    default = fn_get,
    type = "radio",
    fn = fn_set("color3"),
    data = V_data.RGB_datatable
}}

local fn_right = m_util:AddBindShowScreen({
    title = str_show,
    id = "hx_" .. save_id,
    data = screen_data
})
m_util:AddBindConf(save_id, fn_left, nil, {str_show, "quagmire_key",
                                           STRINGS.LMB .. '快捷开关' .. STRINGS.RMB .. '高级设置', true,
                                           fn_left, fn_right})

AddClassPostConstruct("widgets/controls", function(self)
    if not save_data.sw then
        return
    end
    ReMakeKT(self)
end)
