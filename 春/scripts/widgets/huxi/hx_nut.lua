local Widget = require "widgets/widget"
local Text = require "widgets/text"
local h_util = require "util/hudutil"
local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"


local function BuildBadge(icon)
    local bd = Widget("HuxiBadge")
    bd.backing = bd:AddChild(UIAnim())
    bd.backing:GetAnimState():SetBank("status_meter")
    bd.backing:GetAnimState():SetBuild("status_wet")
    bd.backing:GetAnimState():PlayAnimation("bg")

    bd.anim = bd:AddChild(UIAnim())
    bd.anim:GetAnimState():SetBank("status_meter")
    bd.anim:GetAnimState():SetBuild("status_meter")
    bd.SetPercent = function(perc)
        bd.anim:GetAnimState():SetPercent("anim", perc and (1-perc) or 1)
    end
    
    bd.circleframe = bd:AddChild(UIAnim())
    bd.circleframe:GetAnimState():SetBank("status_meter")
    bd.circleframe:GetAnimState():SetBuild("status_meter")
    bd.circleframe:GetAnimState():PlayAnimation("frame")

    bd.bottomframe = bd:AddChild(Image("images/bottom_text_grid.xml", "bottom_text_grid.tex"))
    bd.bottomframe:SetPosition(0, -35, 0)
    bd.bottomframe:SetScale(0.1, 0.1, 1)

    bd.text = bd:AddChild(Text(CHATFONT, 17))
    bd.text:SetPosition(0, -35, 0)
    bd.text:SetString("--%")
    bd.SetText = function(str)
        bd.text:SetString(str or "--%")
    end

    bd.str = bd:AddChild(Text(NUMBERFONT, 20))
    bd.str:SetPosition(0, -60, 0)
    
    bd.SetStr = function(value)
        value = tonumber(value)
        if value then
            if value > 0 then
                bd.str:SetString("↑ "..value)
                bd.str:SetColour(h_util:GetRGB("春绿色"))
            elseif value < 0 then
                bd.str:SetString("↓ "..-value)
                bd.str:SetColour(h_util:GetRGB("红色"))
            else
                bd.str:SetString("==")
                bd.str:SetColour(h_util:GetRGB("白色"))
            end
        else
            bd.str:SetString("")
        end
        if bd._hx_id == "wateringcan" then
            bd.str:SetColour(h_util:GetRGB("矢车菊蓝色"))
        end
    end

    local xml,tex = h_util:GetPrefabAsset(icon)
    if xml and tex then
        bd.img = bd:AddChild(Image(xml, tex))
        bd.img:SetScale(0.5)
    end

    
    return bd
end

local HuxiNut = Class(Widget, function(self, scale)
    Widget._ctor(self, "HuxiNut")
    self.f0 = self:AddChild(BuildBadge("wateringcan"))
    self.f0._hx_id = "wateringcan"
    self.f0.anim:GetAnimState():SetMultColour(48 / 255, 97 / 255, 169 / 255, 1)
    self.f1 = self:AddChild(BuildBadge("soil_amender_fermented"))
    self.f1.anim:GetAnimState():SetMultColour(unpack(h_util:GetWRGB("蓝色")))
    self.f2 = self:AddChild(BuildBadge("spoiled_food"))
    self.f2.anim:GetAnimState():SetMultColour(unpack(h_util:GetWRGB("金黄色")))
    self.f3 = self:AddChild(BuildBadge("poop"))
    self.f3.anim:GetAnimState():SetMultColour(unpack(h_util:GetWRGB("西红柿红色")))
    self:SetUIScale(scale)
end)

function HuxiNut:SetUIScale(scale)
    local spacing = h_util.btn_size * 2* scale
    local _scale = scale+0.4
    local init_x = h_util.screen_w/2 - 1.5*spacing
    local init_y = h_util.screen_h - 0.5*spacing
    for i = 0,3 do
        self["f"..i]:SetScale(_scale)
        self["f"..i]:SetPosition(init_x+i*spacing, init_y, 0)
    end
end


return HuxiNut