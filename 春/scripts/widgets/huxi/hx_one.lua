
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local h_util = require "util/hudutil"
local t_util = require "util/tableutil"
local xml = "images/hx_or.xml"

local HxOne = Class(Widget, function(self, prefab, size, func)
    Widget._ctor(self, "HxOne")
    self.btn = self:AddChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_known.tex"))
    h_util:ActivateBtnScale(self.btn, size)
    self.img = self.btn:AddChild(Image(h_util:GetPrefabAsset(prefab)))
    self.sw = self.btn:AddChild(Image(xml, "right.tex"))
    self.btn:SetOnClick(function()
        self:Switch(not self.show)
    end)
    self:SetPosition(0, 1.2*size, 0)
    self.show = true
    self.func = func
end)

function HxOne:Switch(show)
    self.show = show
    self.sw:SetTexture(xml, show and "right.tex" or "wrong.tex")
    self.func(show)
end

return HxOne

