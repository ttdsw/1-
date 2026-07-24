local t_util = require "util/tableutil"
local keybind = {}
local keys = {
    TAB = "TAB",
    KP_PERIOD = ".",
    KP_DIVIDE = "/",
    KP_MULTIPLY = "*",
    KP_MINUS = "-",
    KP_PLUS = "+",
    KP_ENTER = "ENT",
    KP_EQUALS = "=",
    MINUS = "-",
    EQUALS = "=",
    SPACE = " ",
    ENTER = "ENT",
    ESCAPE = "ESC",
    HOME = "HOME",
    INSERT = "INS",
    DELETE = "DEL",
    END    = "END",
    PAUSE = "PAU",
    PRINT = "PRI",
    CAPSLOCK = "CAP",
    SCROLLOCK = "SCR",
    RSHIFT = "SHIFT",
    LSHIFT = "SHIFT",
    RCTRL = "CTRL",
    LCTRL = "CTRL",
    RALT = "ALT",
    LALT = "ALT",
    LSUPER = "SUP",
    RSUPER = "SUP",
    ALT = "ALT",
    CTRL = "CTRL",
    SHIFT = "SHIFT",
    BACKSPACE = "BACK",
    PERIOD = ".",
    SLASH = "SLA",
    SEMICOLON = "SEMI",
    LEFTBRACKET	= "{",
    BACKSLASH	= "\\",
    RIGHTBRACKET= "}",
    TILDE = "~",
    UP = "↑",
    DOWN = "↓",
    RIGHT = "→",
    LEFT = "←",
    PAGEUP = "↑↑",
    PAGEDOWN = "↓↓",
}
for i = string.byte('A'), string.byte('Z') do
    local char = string.char(i)
    keys[char] = char
end

for i = 1, 12 do
    keys["F"..i] = "F"..i
end
for i = 0, 9 do
    keys["KP_"..i] = i
    keys[tostring(i)] = i
end

keybind.strs = t_util:PairToPair(keys, function(_key_str, str_show)
    return "KEY_".._key_str, str_show
end)


function keybind:GetShow(key_str)
    return key_str and self.strs[key_str]
end

function keybind:GetKeyCode(key_str)
    return key_str and _G[key_str]
end

function keybind:GetKeyStr(keycode)
    return keycode and t_util:GetElement(keybind.strs, function(keystr)
        return _G[keystr] == keycode and keystr
    end)
end

return keybind