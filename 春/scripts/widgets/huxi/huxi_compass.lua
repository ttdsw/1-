local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local h_util = require "util/hudutil"





local CPS = Class(Widget, function(self, funcs, meta)
    Widget._ctor(self, "Huxi Compass")

    
    self.init_x, self.init_y = h_util.screen_w*4/5, h_util.screen_h*4/5
    meta, funcs = meta or {}, funcs or {}
    self.meta, self.funcs = meta, funcs
    self.offset = meta.offset
    self.shake = meta.shake

    local scale = meta.scale or 1

    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("compass_bg")
    self.bg:GetAnimState():SetBuild("compass_bg")
    self.bg:GetAnimState():PlayAnimation("idle")
    self.needle = self:AddChild(UIAnim())
    self.needle:GetAnimState():SetBank("compass_needle")
    self.needle:GetAnimState():SetBuild("compass_needle")
    self.needle:GetAnimState():PlayAnimation("idle", true)
    if meta.text then
        self.text_heading = self:AddChild(Text(NUMBERFONT, 45, "0°"))
        self.text_heading:SetPosition(0, -70)
    end

    h_util:ActivateUIDraggable(self, funcs.SavePos)
    self:SetHoverText(STRINGS.LMB.."可拖拽 \n黏着鼠标请按Esc", {offset_y = -150, colour = UICOLOURS.GOLD, font_size = 18})


    self.headingvel = 0
    self.forceperdegree = 0.005
    self.damping = 0.98
    self.displayheading = self:GetCompassHeading()
    self.currentheading = self.displayheading
    self.offsetheading = 0
    self.easein = 0 

    self:SetScale(scale, scale)
    self:SetUIPos()
    self:StartUpdating()
end)

local function NormalizeHeading(heading)
    while heading < -180 do heading = heading + 360 end
    while heading > 180 do heading = heading -360 end
    return heading
end

local function EaseHeading(heading0, heading1, k)
    local delta = NormalizeHeading(heading1 - heading0)
    return NormalizeHeading(heading0 + math.clamp(delta * k, -20, 20))
end

function CPS:OnUpdate(dt)
    local heading = self:GetCompassHeading()
    if self.text_heading then
        self.text_heading:SetString(string.format(" %d°", heading))
    end
    if not self.shake then
        self.needle:SetRotation(heading)
        return 
    end
    local delta = NormalizeHeading(heading - self.currentheading)
    self.headingvel = self.headingvel + delta * self.forceperdegree
    self.headingvel = self.headingvel * self.damping
    self.currentheading = NormalizeHeading(self.currentheading + self.headingvel)

    if self.offset and ThePlayer and TheWorld then
        local t = GetTime()
        local sanity = ThePlayer.replica.sanity
        local sanity_t = math.clamp((sanity:IsInsanityMode() and sanity:GetPercent() or (1.0 - sanity:GetPercent())) * 3, 0, 1)
        local sanity_offset = math.sin(t*0.2) * Lerp(720, 0, sanity_t)
        
        local fullmoon_t = TheWorld.state.isfullmoon and math.sin(TheWorld.state.timeinphase * math.pi) or 0
        local fullmoon_offset = math.sin(t*0.8) * Lerp(0, 720, fullmoon_t)
        
        local wobble_offset = math.sin(t*2)*5
    
        self.offsetheading = EaseHeading(self.offsetheading, wobble_offset + fullmoon_offset + sanity_offset, .5)
    end

    self.easein = math.min(1, self.easein + dt)
    self.displayheading = EaseHeading(self.displayheading, self.currentheading + self.offsetheading, self.easein)
    self.needle:SetRotation(self.displayheading)
end

function CPS:GetCompassHeading()
    return TheCamera and (TheCamera:GetHeading() - 45) or 0
end


function CPS:SetUIPos(reset)
    if reset then
        self.funcs.SavePos({x = self.init_x, y = self.init_y})
    end
    self:SetPosition(self.meta.posx or self.init_x, self.meta.posy or self.init_y)
end

return CPS