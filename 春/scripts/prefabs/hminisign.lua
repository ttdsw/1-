local e_util = require "util/entutil"



local function fn()
    local inst = e_util:SpawnNull()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("sign_mini")
    inst.AnimState:SetBuild("sign_mini")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(1)
    inst:AddTag("fx")
    inst:AddTag("sign")

    function inst:Draw(xml, tex)
        if xml and tex then
            inst.AnimState:OverrideSymbol("SWAP_SIGN", xml, tex)
        else
            inst.AnimState:ClearOverrideSymbol("SWAP_SIGN")
        end
    end

    return inst
end







return Prefab("hminisign", fn)