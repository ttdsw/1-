AddClassPostConstruct("widgets/redux/serversaveslot", function(self)
	local _SetSaveSlot = self.SetSaveSlot
    self.SetSaveSlot = function(self, ...)
        _SetSaveSlot(self, ...)
        if self.serverslotscreen then
            local character_atlas, character = self.serverslotscreen:GetCharacterPortrait(self.slot)
            if self.slot ~= -1 and character == "mod" then
                local prefab_player = ShardSaveGameIndex:GetSlotCharacter(self.slot)
                if prefab_player then
                    local xml, tex
                    local mods = ShardSaveGameIndex:GetSlotEnabledServerMods(self.slot)
                    for modname in pairs(mods) do
                        local xml, tex = h_util:RegisterIcon_MODCHARACTERLIST(prefab_player, modname)
                        if xml then
                            if t_util:GetRecur(self, "character_portrait.title_portrait.SetTexture") then
                                self.character_portrait.title_portrait:SetTexture(xml, tex)
                            end
                            return
                        end
                    end
                end
            end
        end
    end
end)