local assets_placerindicator = {
    Asset("ANIM", "anim/wagpunk_floor_kit.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("wagpunk_floor_kit_placer")
    inst.AnimState:SetBuild("wagpunk_floor_kit")
    inst.AnimState:PlayAnimation("anim")
    inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetMultColour(0.4, 0.5, 0.6, 0.6)

    return inst
end


return Prefab("hfloorkit", fn)