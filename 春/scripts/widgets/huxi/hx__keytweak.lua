local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local Text = require "widgets/text"
local c_util, e_util, h_util, m_util, t_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil"
local k_util = require "util/keybind"

local Tweak = Class(Widget, function(self, save_data, funcs)
    Widget._ctor(self, "KeyTweak")
    self.root = self:AddChild(Widget("root"))
    self:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
    save_data, funcs = save_data or {}, funcs or {}
    self.root:SetPosition(save_data.init_x or 0, save_data.init_y or 25)
    local shifty = 55
    local shift_space = 108
    local shiftx = 56
    for i, line_data in ipairs(save_data.keytweak) do
        local shift_x = 0
        t_util:IPairs(line_data, function(key_str)
            local show_str = k_util:GetShow(key_str)
            if not show_str then
                return print(key_str, "对应按键不存在！请联系开发者！")
            end
            local id = "HX_KT"..k_util:GetKeyCode(key_str)
            local img = self.root:AddChild(Image(self:GetImages(show_str))) 
            self[id] = img
            local font = save_data.font or HEADERFONT
            local txt = img:AddChild(Text(font, self:GetFontSize(show_str), show_str, h_util:GetRGB(save_data.color3)))

            shift_x = shift_x + (show_str == " " and shift_space or shiftx)
            img:SetPosition(shift_x, (i-1)*shifty)
            shift_x = shift_x + (show_str == " " and shiftx or 0)
            img.func_press = function(down)
                img:SetTexture(self:GetImages(show_str, down))
                img:SetTint(unpack(h_util:GetRGB(down and save_data.color2 or save_data.color1)))
            end
            img:SetScale(0.4)
            img.func_press()
        end)
    end
    self.root:SetScale(save_data.scale or 1)
end)

function Tweak:GetImages(show_str, down)
    if down then
        if show_str == " " then
            return "images/spacedown.xml", "spacedown.tex"
        else
            return "images/keydown.xml", "keydown.tex"
        end
    else
        if show_str == " " then
            return "images/spaceup.xml", "spaceup.tex"
        else
            return "images/keyup.xml", "keyup.tex"
        end
    end
end

function Tweak:GetFontSize(show_str)
    return 100 - #tostring(show_str)*10
end


return Tweak