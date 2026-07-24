local Widget = require "widgets/widget"
local Text = require "widgets/text"
local e_util = require "util/entutil"
local rgb_color = require("data/valuetable").RGB

local Label = Class(Widget, function(self, target, text, offset, font, size, colour)
    Widget._ctor(self, "hx_label")
    colour = colour or "白色"
    self.text = self:AddChild(Text(font or HEADERFONT, size or 35, text or "",  rgb_color[colour] or rgb_color['白色']))
    self:SetOffset(offset or {
        x = 0,
        y = 80
    })
    self:SetTarget(target)
    if target._hx_label then
        target._hx_label:Kill()
    end
    target._hx_label = self
    self:StartUpdating()
end)

function Label:SetText(str)
    self.text:SetString(tostring(str))
    return self
end

function Label:SetFont(font)
    self.text:SetFont(font)
    return self
end

function Label:GetText()
    return self.text:GetString()
end

function Label:SetSize(size)
    size = tonumber(size) or self.text.size
    self.text:SetSize(size)
    return self
end

function Label:SetColor(color)
    color = color or "白色"
    color = rgb_color[color] or rgb_color['白色']
    self.text:SetColour(color)
    return self
end

function Label:SetTarget(target)
    self.target = target
    self.x_init, self.y_init = self:GetPosXY()
    assert(self.x_init, "非法实体或位置")
    return self
end

function Label:SetOffset(offset)
    if tonumber(offset.x) and tonumber(offset.y) then
        self.offset = offset
    else
        print("Offset Wrong!")
    end
    return self
end

function Label:GetPosXY()
    local target = self.target
    if target then
        local x, y = target.x, target.z
        if not x then
            local tf = e_util:IsValid(target)
            if tf then
                if target:HasTag("inlimbo") then
                    self:Hide()
                else
                    self:Show()
                end
                if self.target.AnimState then
                    x, y = TheSim:GetScreenPos(self.target.AnimState:GetSymbolPosition(self.symbol or "", self.offset.x,
                                                                                       self.offset.y, 0))
                else
                    x, y = TheSim:GetScreenPos(tf:GetWorldPosition())
                end
            end
        else
            x, y = TheSim:GetScreenPos(x, 0, y)
        end
        return x, y
    end
end

function Label:OnUpdate(dt)
    local x, y = self:GetPosXY()
    if x and y then
        self:SetPosition(x + self.offset.x, y + self.offset.y, 0)
    else
        self:Kill()
    end
end

return Label
