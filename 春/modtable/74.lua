
local TEMPLATES = require "widgets/redux/templates"
local title, shift = "来自套装", 55


local function GetSkinSetForPrefab(prefab)
    if not table.contains(DST_CHARACTERLIST, prefab) then return end
    local suits = t_util:IPairFilter(TheItems:GetIAPDefs(), function(iap)
        local itp = iap.item_type
        local pattern1 = "_"..prefab.."_"
        local pattern2 = "_"..prefab.."$"
        local pattern3 = "^"..prefab.."_"
        local pack = itp and (
            itp:find(pattern1, 1, true)
            or itp:find(pattern2)
            or itp:find(pattern3)
        ) and MISC_ITEMS[itp]
        if pack then
            local otp = pack.output_items
            local psb = PREFAB_SKINS[prefab]
            if otp and psb then
                local bases = t_util:IPairFilter(otp, function(base)
                    return table.contains(psb, base) and base
                end)
                
                if #bases ~= 1 then return end
                local skins = {base = bases[1]}
                t_util:IPairs(otp, function(skin)
                    local cloth = CLOTHING[skin]
                    local type = cloth and cloth.type
                    if type then
                        if skins[type] then
                            print("功能异常，请联系开发者：", itp, skin, type)
                        else
                            skins[type] = skin
                        end
                    end
                end)
                return {
                    suit = skins,
                    time = type(pack.release_group) == "number" and pack.release_group or 0,
                    itp = itp,
                }
            end
        end
    end)
    table.sort(suits, function(a, b)
        return a.time > b.time
    end)
    return suits
end

local skin_set_default = 
{
    {
        itp = "suit_sleepy1",
        suit = {
            body = "body_pj_blue_agean",
            legs = "legs_pj_blue_agean",
        },
    },
    {
        itp = "suit_sleepy2",
        suit = {
            body = "body_pj_red_redbird",
            legs = "legs_pj_red_redbird",
        },
    },
    {
        itp = "suit_sleepy3",
        suit = {
            body = "body_pj_grey",
            legs = "legs_pj_grey",
        },
    },
    {
        itp = "suit_yawn1",
        suit = {
            body = "body_pj_purple_mauve",
            legs = "legs_pj_purple_mauve",
        },
    },
    {
        itp = "suit_yawn2",
        suit = {
            body = "body_pj_green_hunters",
            legs = "legs_pj_green_hunters",
        },
    },
    {
        itp = "suit_yawn3",
        suit = {
            body = "body_pj_orange_honey",
            legs = "legs_pj_orange_honey",
        },
    },
    {itp = "none"},
}

local function GetSuitName(prefabname, itp)
    local name = GetSkinName(itp)
    if name == STRINGS.SKIN_NAMES.missing then
        if itp:find("sleepy") then
            name = STRINGS.SET_NAMES.emote_sleepy..itp:sub(-1)
        elseif itp:find("yawn") then
            name = STRINGS.SET_NAMES.emote_yawn..itp:sub(-1)
        end
    end
    return name:gsub(prefabname, ""):gsub(STRINGS.SKIN_TAG_CATEGORIES.ITEM.CHEST, ""):gsub(STRINGS.UI.COLLECTIONSCREEN.SET_INFO, ""):gsub("的", "")
end

local function GetPlayerSuits(prefab, list_ban)
    local suits = t_util:MergeList(GetSkinSetForPrefab(prefab) or {}, skin_set_default)
    local prefabname = e_util:GetPrefabName(prefab)
    prefabname = prefabname:gsub("%-", "%%%-") 
    t_util:IPairs(suits, function(suit)
        suit.name = GetSuitName(prefabname, suit.itp)
    end)
    if list_ban then
        t_util:IPairs(list_ban, function(ban)
            t_util:IPairs(suits, function(suit)
                if suit.suit and suit.suit[ban] then
                    suit.suit[ban] = nil
                end
            end)
        end)
    end
    return suits
end

local function BuildPlayerSuitBtn(prefab, fn, list_ban)
    local xml, tex = h_util:GetPrefabAsset("reskin_tool_brush")
    local btn = TEMPLATES.IconButton(xml, tex, title, false, false, function()
            local suits = GetPlayerSuits(prefab, list_ban)
            local suit_screen = require "screens/huxi/suitscreen" 
            TheFrontEnd:PushScreen(suit_screen(suits, {title = title}, prefab, fn))
        end)
    btn:SetScale(0.77)
    return btn
end


AddClassPostConstruct("screens/redux/wardrobescreen", function(self)
    if not self.presetsbutton then return end
    self.btn_suit = self.root:AddChild(BuildPlayerSuitBtn(self.currentcharacter, function(skins) self:ApplySkinPresets(skins) end))
    self.btn_suit:SetPosition(-480+shift, 212)
end)


AddClassPostConstruct("screens/redux/wardrobepopupgridloadout", function(self)
    if not t_util:GetRecur(self, "loadout.presetsbutton") then return end
    local loadout = self.loadout
    loadout.btn_suit = loadout.loadout_root.wardrobe_root:AddChild(BuildPlayerSuitBtn(self.owner_player.prefab, function(skins) loadout:ApplySkinPresets(skins) end))
    loadout.btn_suit:SetPosition(200-shift, 315)
end)


AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
    t_util:IPairs(self.panels or {}, function(fn_data)
        local LoadoutPanel = fn_data.panelfn
        if not type(LoadoutPanel)=="table" then return end
        local __ctor = LoadoutPanel._ctor
        if not __ctor then return end
        LoadoutPanel._ctor = function(self, owner, ...)
            local ret = __ctor(self, owner,...)
                if t_util:GetRecur(self, "loadout.presetsbutton") then
                    local loadout = self.loadout
                    loadout.btn_suit = loadout.loadout_root.wardrobe_root:AddChild(BuildPlayerSuitBtn(owner.lobbycharacter, function(skins) loadout:ApplySkinPresets(skins) end))
                    loadout.btn_suit:SetPosition(loadout.itemskinsbutton and 200-2*shift or 200-shift, 315)
                end
            return ret
        end
    end)
end)




AddClassPostConstruct("screens/redux/scarecrowpopupgridloadout", function(self)
    if not t_util:GetRecur(self, "loadout.loadout_root.wardrobe_root") then return end
    local loadout = self.loadout
    loadout.btn_suit = loadout.loadout_root.wardrobe_root:AddChild(BuildPlayerSuitBtn(ThePlayer and ThePlayer.prefab, function(skins) loadout:ApplySkinPresets(skins) end, {"base"}))
    loadout.btn_suit:SetPosition(200+shift/2, 315)
end)


local function GetBeefaloSuits()
    
    local suits = t_util:PairToIPair(BEEFALO_CLOTHING, function(hornname, iap)
        if not (hornname:find("_horn_") and iap.type) then return end
        local skin = {
            name = GetSkinName(hornname):gsub(STRINGS.NAMES.HORN, ""),
            time = type(iap.release_group) == "number" and iap.release_group or 0,
            suit = {
                [iap.type] = hornname
            }
        }
        skin.time = skin.time == 999 and -1 or skin.time 
        t_util:IPairs({"body", "feet", "head", "tail"}, function(point)
            local pointname = hornname:gsub("_horn_", "_"..point.."_")
            local iap = BEEFALO_CLOTHING[pointname]
            if iap and iap.type then
                skin.suit[iap.type] = pointname
            end
        end)
        return skin
    end)
    table.sort(suits, function(a, b)
        return a.time > b.time
    end)
    return suits
end


local function BuildBeefaloSuitBtn(fn)
    local xml, tex = h_util:GetPrefabAsset("brush")
    local btn = TEMPLATES.IconButton(xml, tex, title, false, false, function()
            local suits = GetBeefaloSuits()
            local suit_screen = require "screens/huxi/beefaloscreen" 
            TheFrontEnd:PushScreen(suit_screen(suits, {title = title}, fn))
        end)
    btn:SetScale(0.77)
    return btn
end


AddClassPostConstruct("widgets/redux/beefaloexplorerpanel", function(self)
    if not self.presetsbutton then return end
    self.btn_suit = self.puppet_root:AddChild(BuildBeefaloSuitBtn(function(skins) self:ApplySkinSet(skins) self:TryToClickSelected() end))
    self.btn_suit:SetPosition(-240+shift, 440)
end)


AddClassPostConstruct("widgets/redux/loadoutselect_beefalo", function(self)
    if not self.presetsbutton then return end
    self.btn_suit = self.loadout_root:AddChild(BuildBeefaloSuitBtn(function(skins) self:ApplySkinPresets(skins) end))
    self.btn_suit:SetPosition(200-shift, 315)
end)

Mod_ShroomMilk.Func.GetSkinSetForPrefab = GetSkinSetForPrefab