local TE = require "widgets/redux/templates"
local Text = require "widgets/text"
local _ModListItem = TE.ModListItem
TE.ModListItem = function(...)
    local opt = _ModListItem(...)
    local _SetMod = opt.SetMod
    opt.SetMod = function(_, modname, modinfo, modstatus, isenabled, isfavorited)
        _SetMod(_, modname, modinfo, modstatus, isenabled, isfavorited)
        local _modname = modinfo and modinfo.name
        if _modname then
            opt.setfavorite.image:SetTint(unpack(h_util:GetRGB(_modname:find("群鸟绘卷") and "标紫" or "白色")))
            if opt.addname then
                opt.addname:Kill()
            end
            local w, h = opt.name:GetRegionSize()
            opt.name:SetPosition(w * .5 - 75, 20, 0)
            opt.addname = opt.backing:AddChild(Text(CHATFONT, 18, "\n" .. modname, UICOLOURS.GOLD_CLICKABLE))
            w, h = opt.addname:GetRegionSize()
            opt.addname:SetPosition(w * .5 - 75, -2, 0)
            if _modname:find("风华") then
                local ver = tonumber(modinfo.version)
                if ver and ver >= 4 then
                    opt.addname:SetString("󰀜")
                end
            end
        end
    end
    return opt
end



local ModsTab = require "widgets/redux/modstab"
local _ShowModDetails = ModsTab.ShowModDetails
ModsTab.ShowModDetails = function(self, widget_idx, client_mod)
    local ret = _ShowModDetails(self, widget_idx, client_mod)
    if self.detailauthor then
        local items_table = client_mod and self.optionwidgets_client or self.optionwidgets_server
        local modnames_versions = client_mod and self.modnames_client or self.modnames_server
        local idx = items_table[widget_idx] and items_table[widget_idx].index
        local modname = idx and modnames_versions[idx] and modnames_versions[idx].modname
        if modname then
            local modinfo = KnownModIndex:GetModInfo(modname) or {}
            local version_m = type(modinfo.version) == "string" and modinfo.version
            if version_m then
                local author_m = self.detailauthor:GetString()
                self.detailauthor:SetString(author_m .. "  " .. STRINGS.UI.MAINSCREEN.DST_UPDATENAME .. "：" ..
                                                version_m)
                local w, h = self.detailauthor:GetRegionSize()
                local align = self.detailauthor._align
                self.detailauthor:SetPosition((w or 0) / 2 - align.x, align.y)
            end
            local version_w = version_m and IsWorkshopMod(modname) and TheSim:GetWorkshopVersion(modname)
            if version_w and version_w ~= version_m and self.detailwarning then
                self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.WORKSHOP_FILTER .. " " ..
                                                 STRINGS.UI.MAINSCREEN.DST_UPDATENAME .. "：" .. version_w)
                self.detailwarning:SetColour(PLAYERCOLOURS.RED)
            end
        end
    end
    return ret
end
