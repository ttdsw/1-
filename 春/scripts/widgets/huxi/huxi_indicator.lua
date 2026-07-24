local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local c_util, e_util, h_util, m_util, t_util,p_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil",
require "util/playerutil"


local DEFAULT_ATLAS = "images/avatars.xml"
local DEFAULT_AVATAR = "avatar_unknown.tex"
local ARROW_OFFSET = 65







local Intor = Class(Widget, function(self, target, xml, tex, name, funcs, meta)
    Widget._ctor(self, "huxi_indicator")
    self:Hide()
    self.root = self:AddChild(Widget("root"))
    

    meta, funcs = meta or {}, funcs or {}
    self.meta, self.funcs = meta, funcs
    self.owner = meta.player or ThePlayer
    self.target = target
    self.min_scale, self.max_scale = meta.min_scale or 0.5, meta.max_scale or 1

    
    self.icon = self.root:AddChild(Image(DEFAULT_ATLAS, "avatar_bg.tex"))
    self.headframe = self.icon:AddChild(Image(DEFAULT_ATLAS, "avatar_frame_white.tex"))
    self.head = self.icon:AddChild(Image(xml, tex))
    local icon_size = self.icon:GetSize()
    local head_size = self.head:GetSize()
    self.head:SetScale(icon_size/head_size*0.6)

    self.arrow = self.root:AddChild(Image("images/ui.xml", "scroll_arrow.tex"))
    self.arrow:SetScale(.5)


    self.name_label = self.icon:AddChild(Text(UIFONT, 45, name))
    self.name_label:Hide()

    
    local color = h_util:GetRGB(meta.color or "漆白")
    local r,g,b,a = unpack(color)
    self.headframe:SetTint(r, g, b, a)
    self.arrow:SetTint(r, g, b, a)
    self.name_label:SetColour(r, g, b, a)

    
    h_util:BindMouseClick(self.icon, {[MOUSEBUTTON_LEFT] = function()
        if type(funcs.fn_left)=="function" then
            funcs.fn_left(self, self.target)
        end
    end})

    self:StartUpdating()
end)

function Intor:OnUpdate()
    if self.meta.hide then
        
        return self:Hide()
    else
        self:Show()
    end
    local trans_p = e_util:IsValid(self.owner)
    if not trans_p then
        return
    end
    local trans_t = e_util:IsValid(self.target)
    if not trans_t then
        return self:Kill()
    end
    if e_util:OnPlayerScreen(self.target) then
        return self:Hide()
    end
    local px, _, pz = trans_p:GetWorldPosition()
    local tx, _, tz = trans_t:GetWorldPosition()
    local dist = c_util:GetDist(px, pz, tx, tz)


    
    if dist < TUNING.MIN_INDICATOR_RANGE then
        dist = TUNING.MIN_INDICATOR_RANGE
    elseif dist > TUNING.MAX_INDICATOR_RANGE then
        dist = TUNING.MAX_INDICATOR_RANGE
    end
    
    local scale = Remap(dist, TUNING.MIN_INDICATOR_RANGE, TUNING.MAX_INDICATOR_RANGE, self.max_scale, self.min_scale)
    self:SetScale(scale)

    
    self:UpdatePosition(tx, tz)
end

function Intor:UpdatePosition(targX, targZ)
    local w0, h0 = self.head:GetSize()
    local w1, h1 = self.arrow:GetSize()
    local scale = self:GetScale()
    local w = ((w0 or 0) + (w1 or 0)) * 0.5 * scale.x
    local h = ((h0 or 0) + (h1 or 0)) * 0.5 * scale.y
    local x, y, angle = GetIndicatorLocationAndAngle(self.owner, targX, targZ, w, h)

    self:SetPosition(x, y, 0)
    self.x = x
    self.y = y
    self.angle = angle
    self:PositionArrow()
    self:PositionLabel()
end

function Intor:PositionArrow()
    if not self.x and self.y and self.angle then return end
    local angle = self.angle + 45
    self.arrow:SetRotation(angle)
    local x = math.cos(angle*DEGREES) * ARROW_OFFSET
    local y = -(math.sin(angle*DEGREES) * ARROW_OFFSET)
    self.arrow:SetPosition(x, y, 0)
end

function Intor:PositionLabel()
    if not self.x and self.y and self.angle then return end

    local angle = self.angle + 45 - 180
    local x = math.cos(angle*DEGREES) * ARROW_OFFSET * 1.75
    local y = -(math.sin(angle*DEGREES) * ARROW_OFFSET  * 1.25)
    self.name_label:SetPosition(x, y, 0)
end

function Intor:OnGainFocus()
    Intor._base.OnGainFocus(self)
    self.name_label:Show()
end

function Intor:OnLoseFocus()
    Intor._base.OnLoseFocus(self)
    self.name_label:Hide()
end

return Intor