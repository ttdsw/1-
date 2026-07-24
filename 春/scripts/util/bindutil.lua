


local t_util = require "util/tableutil"
local keys = {"KEY_TAB", "KEY_KP_0", "KEY_KP_1", "KEY_KP_2", "KEY_KP_3", "KEY_KP_4", "KEY_KP_5", "KEY_KP_6", "KEY_KP_7",
              "KEY_KP_8", "KEY_KP_9", "KEY_KP_PERIOD", "KEY_KP_DIVIDE", "KEY_KP_MULTIPLY", "KEY_KP_MINUS",
              "KEY_KP_PLUS", "KEY_KP_ENTER", "KEY_KP_EQUALS", "KEY_MINUS", "KEY_EQUALS", "KEY_HOME", "KEY_INSERT",
              "KEY_DELETE", "KEY_END", "KEY_PAUSE", "KEY_PRINT", "KEY_CAPSLOCK", "KEY_SCROLLOCK", "KEY_A", "KEY_B",
              "KEY_C", "KEY_D", "KEY_E", "KEY_F", "KEY_G", "KEY_H", "KEY_I", "KEY_J", "KEY_K", "KEY_L", "KEY_M",
              "KEY_N", "KEY_O", "KEY_P", "KEY_Q", "KEY_R", "KEY_S", "KEY_T", "KEY_U", "KEY_V", "KEY_W", "KEY_X",
              "KEY_Y", "KEY_Z", "KEY_F1", "KEY_F2", "KEY_F3", "KEY_F4", "KEY_F5", "KEY_F6", "KEY_F7", "KEY_F8",
              "KEY_F9", "KEY_F10", "KEY_F11", "KEY_F12", "KEY_0", "KEY_1", "KEY_2", "KEY_3", "KEY_4", "KEY_5", "KEY_6",
              "KEY_7", "KEY_8", "KEY_9", "KEY_UP", "KEY_DOWN", "KEY_RIGHT", "KEY_LEFT", "KEY_PAGEUP", "KEY_PAGEDOWN"}

local bind_basic = t_util:IPairToPair(keys, function(key)
    local desc = key:gsub("KEY_", "")
    return _G[key], {
        code = _G[key], 
        desc = desc,
        show = string.len(desc) <= 3 and desc
    }
end)
local function fn_keyload(pre_id, pre_show)
    return t_util:PairToPair(bind_basic, function(id, basic)
        return pre_id .. id, {
            code = basic.code, 
            desc = pre_show .. basic.desc,
            show = basic.show and pre_id .. basic.show
        }
    end)
end
local bind_ctrl = fn_keyload("C", "CTRL+")
local bind_shift = fn_keyload("S", "SHIFT+")
local bind_alt = fn_keyload("A", "ALT+")
local bind_0 = {
    code = -1,
    desc = "尚未绑定",
    show = ""
}
local bind_zero = {[-1] = bind_0}

local bind_can = t_util:MergeMap(bind_basic, bind_ctrl, bind_shift, bind_alt)
local bind_all = t_util:MergeMap(bind_zero, bind_can)

local b_util = {}

function b_util:GetShowShort(id)
    return id and bind_all[id] and bind_all[id].show or bind_0.show
end

function b_util:GetShowLabel(id)
    return id and bind_all[id] and bind_all[id].desc or bind_0.desc
end

function b_util:GetKeyCode(id)
    return id and bind_can[id] and bind_can[id].code
end

function b_util:GetKeyValue(keycode)
    if keycode and bind_basic[keycode] then
        return (TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) and t_util:GetElement(bind_ctrl, function(id, bind)
            return bind.code == keycode and id
        end) or (TheInput:IsControlPressed(CONTROL_FORCE_TRADE) and t_util:GetElement(bind_shift, function(id, bind)
            return bind.code == keycode and id
        end) 
        or (TheInput:IsControlPressed(CONTROL_FORCE_INSPECT)and t_util:GetElement(bind_alt, function(id, bind)
            return bind.code == keycode and id
        end))
    )) or keycode
    end
end

function b_util:PackKeyFunc(func, id)
    return id and function()
        if bind_ctrl[id] then
            return TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) and func()
        elseif bind_shift[id] then
            return TheInput:IsControlPressed(CONTROL_FORCE_TRADE) and func()
        elseif bind_alt[id] then
            return TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and func()
        else
            return not b_util:IsPressCSA() and func()
        end
    end
end

function b_util:IsPressCSA()
    return TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) or TheInput:IsControlPressed(CONTROL_FORCE_TRADE) or TheInput:IsControlPressed(CONTROL_FORCE_INSPECT)
end

return b_util
