local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local c_util = require "util/calcutil"



local ScreenScreen = Class(Screen, function(self, title, info_btn)
    Screen._ctor(self, "WriteScreen")
    self.back = self:AddChild(TEMPLATES.BackgroundTint())
    self.proot = self:AddChild(TEMPLATES.ScreenRoot())
    local title = title or "请在此输入："

    self.info_btn = info_btn or {}
    self.info_btn.text = self.info_btn.text or "就这样吧"

    local btns = {{text = h_util.no}, self.info_btn}
    btns = t_util:IPairFilter(btns, function (btn)
        return type(btn.text)=="string" and {text = btn.text, cb = function ()
            if type(btn.cb) == "function" then
                btn.cb(self:GetTextString())
            end
            TheFrontEnd:PopScreen(self)
        end}
    end)

    self.window = self.proot:AddChild(TEMPLATES.CurlyWindow(400, 100, title, btns))
    if self.window.body then 
        self.window.body:SetColour({1, 1, 1, 1})
    end
    self.editbox = self.window:AddChild(h_util:CreateTextEdit({fieldtext = info_btn.fieldtext, hover = "", prompt = "", pos = {0, 32}, fn = function()
        local btn = self:GetResultBtn()
        if not btn then
            return
        end
        local text = self:GetTextString()
        if text ~= "" then
            btn:Enable()
        else
            btn:Disable()
        end
    end}))

    local btn = self:GetResultBtn()
    if btn then
        btn:Disable()
    end
end)

function ScreenScreen:GetTextString()
    local textedit = t_util:GetRecur(self, "editbox.textbox")
    return textedit and c_util:TrimString(textedit:GetString()) or ""
end

function ScreenScreen:GetResultBtn()
    local menu = t_util:GetRecur(self, "window.actions") or {}
    return t_util:IGetElement(menu.items or {}, function(btn)
        local str = btn.text and btn.text:GetString()
        return str and str == self.info_btn.text and btn
    end)
end


function ScreenScreen:OnBecomeActive()
    ScreenScreen._base.OnBecomeActive(self)

    self.editbox.textbox:SetFocus()
    self.editbox.textbox:SetEditing(true)
end
function ScreenScreen:OnControl(control, down)
    if ScreenScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen(self)
        return true
    end
end

return ScreenScreen