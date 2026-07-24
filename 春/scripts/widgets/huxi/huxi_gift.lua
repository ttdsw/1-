local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"
local h_util = require "util/hudutil"
local HuxiGift = Class(Widget, function(self, prefab, right)
    Widget._ctor(self)
    self.proot = self:AddChild(Widget("ROOT"))

    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)

    if right then
        self.proot:SetPosition(h_util:ToSize(730, 300))
        self.proot:SetScale(.6)
    else
        self.proot:SetPosition(h_util:ToSize(-500, 300))
        self.proot:SetScale(.5)
    end

    self.spawn_portal = self.proot:AddChild(UIAnim())
    self.spawn_portal:GetAnimState():SetBuild("skingift_popup") 
    self.spawn_portal:GetAnimState():SetBank("gift_popup") 
	
	
    self.banner = self.proot:AddChild(Image("images/giftpopup.xml", "banner.tex"))
    self.banner:SetPosition(0, -200, 0)

    
    if right then
        self.pre = self.banner:AddChild(Text(HEADERFONT, 45, "皮肤预览", UICOLOURS.GOLD_SELECTED))
        self.pre:SetPosition(0, 370, 0)
    end
    self.name_text = self.banner:AddChild(Text(UIFONT, 55))
    self.name_text:SetPosition(0, -10, 0)
    
    
    self.name_text:SetTruncatedString(GetSkinName(prefab), 500, 35, true)
    self.name_text:SetColour(GetColorForItem(prefab))
    self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", GetBuildForItem(prefab), "SWAP_ICON")
    if not right then
        self.spawn_portal:GetAnimState():PlayAnimation("activate") 
        self.spawn_portal:GetAnimState():PushAnimation("open") 
    end
    self.spawn_portal:GetAnimState():PushAnimation("skin_loop") 
    if not right then
        self.spawn_portal:GetAnimState():PushAnimation("skin_out")
        h_util:PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_spin")
    
        local count = 1
        self.spawn_portal.inst:ListenForEvent("animover", function()
            if count == 1 then
                h_util:PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation")
            elseif count == 2 then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/player_recieves_gift_idle", "gift_idle")
            elseif count == 3 then
                h_util:PlaySound("dontstarve/HUD/Together_HUD/player_receives_gift_animation_skinout")
            end
            count = count + 1
            if self.spawn_portal:GetAnimState():AnimDone() then
                TheFrontEnd:GetSound():KillSound("gift_idle")
                self:Kill()
            end
        end)
    end

    self:SetClickable(false)
end)


return HuxiGift