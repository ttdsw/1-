local confs = {"pocketwatch_heal", "pocketwatch_warp", "pocketwatch_recall"}

t_util:IPairs(confs, function(prefab)
    m_util:AddBindConf(prefab, function()
        if m_util:InGame() ~= "wanda" then
            return
        end
        local item = p_util:GetItemFromAll(prefab, "pocketwatch_inactive", nil, "mouse")
        if not item then
            return
        end
        local act = p_util:GetAction("inv", "CAST_POCKETWATCH", true, item)
        if act then
            p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, item)
        end
    end, true)
end)
