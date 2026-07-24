local comp_rep = require "components/combat_replica"
local _IsAlly = comp_rep.IsAlly
comp_rep.IsAlly = function(self, guy, ...)
    if self.inst ~= ThePlayer then
        return
    end
    if guy:HasTag("wall") then
        return true
    else
        local prefab = guy.prefab
        if prefab == "pumpkin_lantern" or (prefab == "stalker_atrium" and e_util:FindEnt(guy, "shadowchanneler", 30)) or
            ((guy:HasTag("stalkerminion") and Mod_ShroomMilk.Func.CanAttackSM and Mod_ShroomMilk.Func.CanAttackSM())) or
            (prefab == "daywalker" and e_util:FindEnt(guy, "shadow_leech", 30)) then
            return true
        end
    end
    return _IsAlly(self, guy, ...)
end
