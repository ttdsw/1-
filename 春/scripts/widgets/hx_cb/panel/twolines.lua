local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local text_default = STRINGS.LMB.."生成实体  "..STRINGS.RMB.."终止生成"


local TL = Class(Image, function(self, text)
    Image._ctor(self, "images/skilltree.xml", "wilson_background_text.tex")

    self:SetVAnchor(ANCHOR_TOP)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetSize(300, 75)

    self:AddChild(Text(CHATFONT, 30, text or text_default, {0, 0, 0, 1 }))
end)



return TL