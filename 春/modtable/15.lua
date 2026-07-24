local MCover = require "widgets/huxi/hx_maincover"
local data_banner = require "data/bannertable"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"

local ui_list = {"hicon", "motd_panel", "onlinestatus", "menu_root", "logo", "sidebar", "submenu", "build_number",
                 "kit_puppet"}
local save_id, str_show = "sw_multiscreen", "壁纸模式"
local default_data = {
    id = 0
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local notfunc = {"MakeYOTDBanner", "MakeYOTCBanner", "MakeWurtWinonaQOLBanner", "MakeHallowedNights2024Banner",
                 "MakeYOTRBanner", "MakeYOTCatcoonBanner", "MakeHalloweenBanner", "MakeHalloween2023Banner",
                 "MakeHalloween2022Banner", "MakeHalloween2021Banner", "MakeRift4Banner"}

local function RegisterSinglAnim(prefab, filename)
    if not Prefabs[prefab] then
        local pref = Prefab(prefab, nil, {Asset("ANIM", "anim/" .. filename .. ".zip")}, nil, true)
        RegisterSinglePrefab(pref)
        TheSim:LoadPrefabs({pref.name})
    end
end
local function RegisterAnims(prefabs)
    if type(prefabs) == "table" then
        t_util:IPairs(prefabs, function(prefab)
            RegisterSinglAnim("modfrontend_" .. prefab, prefab)
        end)
    elseif prefabs then
        RegisterSinglAnim("modfrontend_" .. prefabs, prefabs)
    end
end


local function VisableUI(self, hide)
    local func = hide and "Hide" or "Show"
    t_util:IPairs(ui_list, function(ui_str)
        local ui = self[ui_str]
        if ui and ui[func] then
            ui[func](ui)
        end
    end)
    local banners = self.banner_root and self.banner_root.children
    t_util:Pairs(banners or {}, function(ui)
        if h_util:GetType(ui) ~= "UIAnim" and ui[func] then
            ui[func](ui)
        end
    end)
end

local function SetFrontend(self, id)
    t_util:IPairs(self.banner_root.need_kill or {}, function(ui)
        ui:Kill()
    end)
    self.banner_root.need_kill = nil
    self.banner_root:SetPosition(0, 0)
    if h_util:IsValid(self.mod_darkbg) then
        self.mod_darkbg:Kill()
    end

    local anim = t_util:GetElement(self.banner_root:GetChildren(), function(ui)
        if tostring(ui) == "UIAnim" and h_util:IsValid(ui) then
            return ui
        end
    end)
    if not anim then
        return
    end

    local fn, bg
    if id < 1 then
        local fn_env = c_util:GetFnEnv(MakeBanner)
        fn = t_util:GetElement(fn_env, function(key, val)
            return type(val) == "function" and key:find("Banner") and not table.contains(notfunc, key) and val
        end) or fn_env.MakeHallowedNights2024Banner
    else
        local data = data_banner[id]
        RegisterAnims(data.anim)
        if data.pos then
            self.banner_root:SetPosition(data.pos[1] * RESOLUTION_X, data.pos[2] * RESOLUTION_Y)
        else
            self.banner_root:SetPosition(-0.06 * RESOLUTION_X, -0.07 * RESOLUTION_Y)
        end
        bg = data.bg
        fn = data.fn
    end
    if fn then
        fn(self, self.banner_root, anim)
    end
    if bg then
        self.mod_darkbg = self.fixed_root:AddChild(Image("images/bg_redux_dark_right.xml", "dark_right.tex"))
        self.mod_darkbg:MoveToBack()
        self.mod_darkbg:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.mod_darkbg:SetVAnchor(ANCHOR_MIDDLE)
        self.mod_darkbg:SetHAnchor(ANCHOR_MIDDLE)
    end
end

local function SetDesc(id)
    if id == 0 then
        return "默认主界面"
    else
        local data = data_banner[id]
        local desc = data and data.desc
        if desc then
            return desc
        end
    end
    return ""
end

local function Save()
    s_mana:Save()
end

local meta_data = {
    len = #data_banner
}
local funcs = {
    VisableUI = VisableUI,
    SetFrontend = SetFrontend,
    SetDesc = SetDesc,
    Save = Save
}
AddClassPostConstruct("screens/redux/multiplayermainscreen", function(self)
    self:AddChild(MCover(self, funcs, save_data, meta_data))
    if save_data.id ~= 0 then
        SetFrontend(self, save_data.id)
    end
end)












