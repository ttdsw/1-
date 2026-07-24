local h_util = require "util/hudutil"
local e_util = require "util/entutil"





local function SetRadius(self, radius)
    radius = radius > 0 and radius or 0.01
    local scale = math.sqrt(radius * 300 / 1900)
    self.Transform:SetScale(scale, scale, scale)
    return self
end

local function SetFixedRadius(self, radius)
    radius = radius > 0 and radius or 0.01
    local trans = e_util:IsValid(self.entity and self.entity:GetParent())
    if trans then
        local s1, s2, s3 = trans:GetScale()
        local scale = math.sqrt(radius * 300 / 1900)
        self.Transform:SetScale(scale/s1, scale/s2, scale/s3)
    end
    return self
end



local function fn()
    local inst = e_util:SpawnNull()
    inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    anim:SetBank("firefighter_placement")
    anim:SetBuild("firefighter_placement")
    anim:PlayAnimation("idle")
    anim:SetOrientation(ANIM_ORIENTATION.OnGround)
    anim:SetLayer(LAYER_BACKGROUND)
    
    

    inst.SetRadius = SetRadius
    inst.SetColor = h_util.SetColor
    inst.SetVisable = h_util.SetVisable
    inst.SetFixedRadius = SetFixedRadius

    return inst
end


return Prefab("hrange", fn)