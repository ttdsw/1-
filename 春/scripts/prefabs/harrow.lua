local h_util = require "util/hudutil"
local e_util = require "util/entutil"


local function Link(self, from, to)
    from,to = e_util:IsValid(from), e_util:IsValid(to)
    if from and to then
        local x1, y1, z1 = from:GetWorldPosition()
        local x2, y2, z2 = to:GetWorldPosition()
        self.Transform:SetRotation(math.atan2(x1-x2, z1-z2)*180/math.pi)
    end
    return self
end

local function GoTo(self, from, to, speed)
    Link(self, from, to)
    if e_util:IsValid(from) then
        self.Transform:SetPosition(from:GetPosition():Get())
    end
    speed = (speed == 0 or type(speed)~="number") and -10 or speed
    self.Physics:SetMotorVel(0,0,speed)
    speed = speed > 0 and speed or - speed
    local dist = e_util:GetDist(from, to)
    local countdown = dist and (dist-2.5) / speed or 0
    self:DoTaskInTime(countdown > 0 and countdown or 0, self.Remove)
end

local function fn()
    local inst = e_util:SpawnNull()

    inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local phys = inst.entity:AddPhysics()

    phys:SetMass(2)
	phys:SetFriction(.1)
	phys:SetDamping(0)
	phys:SetSphere(.5)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.GROUND)


    anim:SetBuild("archive_resonator")
    anim:SetBank("archive_resonator")
    anim:PlayAnimation("beam_marker")
    anim:SetOrientation(ANIM_ORIENTATION.OnGround)
    anim:SetLayer(LAYER_BACKGROUND)
    anim:SetSortOrder(3)
    anim:SetBloomEffectHandle("shaders/anim.ksh")
    anim:SetLightOverride(1)
    


    inst.SetColor = h_util.SetColor
    inst.Link = Link
    inst.GoTo = GoTo

    return inst
end


return Prefab("harrow", fn)