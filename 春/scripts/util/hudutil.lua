local t_util = require "util/tableutil"
local c_util = require "util/calcutil"
local r_data = require "data/redirectdata"
local e_util = require "util/entutil"
local i_util = require "util/inpututil"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PopupDialogScreen = require "screens/redux/popupdialog"
local Label = require "widgets/huxi/hx_label"
local ImageButton = require "widgets/imagebutton"
local xml_quag = "images/quagmire_recipebook.xml"
local xml_ui = "images/ui.xml"
local xml_hud = "images/hud.xml"
local xml_hx = "images/hx_ui.xml"
local xml_slice = "images/dialogrect_9slice.xml"
local TwoLines = require "widgets/hx_cb/panel/twolines"
local URL_teach = "https://www.bilibili.com/video/BV1tV411w7oU/?app_platform=pc&app_version=7.0.2"


local h_util = {
    doubleclicktime = 0.3,
    xml_path = {"hx_icons1.xml", "hx_icons2.xml", "button_icons.xml", "button_icons2.xml", "serverplaystyles.xml",
                "quagmire_recipebook.xml", "skilltree.xml", "global_redux.xml","crafting_menu_icons.xml" 
    },
    minimap_path = {"minimap/minimap_data.xml", "minimap/minimap_data1.xml", "minimap/minimap_data2.xml"},
    ok = "俺晓得哩",
    cancel = "关闭",
    error = "错误！",
    yes = STRINGS.UI.OPTIONS.OK,
    no = STRINGS.UI.CONTROLSSCREEN.CANCEL,
    screen_x = RESOLUTION_X,
    screen_y = RESOLUTION_Y,
    prefab_size = 70,
    style = {
        
        
        imgbtn = {
            
            default = {xml_quag, "cookbook_known.tex", "cookbook_known_selected.tex"},
            quag = {xml_quag, "cookbook_known.tex", "cookbook_known_selected.tex"},
            
            ui = {xml_ui, "in-window_button_tile_hl.tex", "in-window_button_tile_hl_noshadow.tex"},
            
            craft = {xml_hx, "cb_cate_bg.tex", "cb_cate_bg_focus.tex", "cb_cate_bg_sel_focus.tex", nil, "cb_cate_bg_sel.tex"},
            
            inv = {xml_hx, "inv_bg.tex", "inv_bg_focus.tex"}
        },
        scrollbar = {
            default = {
                atlas = xml_quag,
                up = "quagmire_recipe_scroll_arrow_hover.tex",
                down = "quagmire_recipe_scroll_arrow_hover.tex",
                bar = "quagmire_recipe_scroll_bar.tex",
                handle = "quagmire_recipe_scroll_handle.tex",
            },
            light = {
                atlas = xml_hx,
                up = "scrollbar_arrow_up_hl.tex",
                down = "scrollbar_arrow_down_hl.tex",
                bar = "scrollbar_bar.tex",
                handle = "scrollbar_handle.tex",
            },
            black = {
                atlas = xml_ui,
                up = "arrow_scrollbar_up.tex",
                down = "arrow_scrollbar_down.tex",
                bar = "scrollbarline.tex",
                handle = "scrollbarbox.tex",
                scale = 1.0
            },
            gold = {
                atlas = "images/global_redux.xml",
                up = "scrollbar_arrow_up.tex",
                down = "scrollbar_arrow_down.tex",
                bar = "scrollbar_bar.tex",
                handle = "scrollbar_handle.tex",
                scale = 0.3
            },
        },
        border = {
            default = {xml_quag, "quagmire_recipe_line.tex"},
            light = {"images/hx_ui.xml", "quagmire_recipe_line.tex"},
        }
    },
    url = URL_teach,
}
h_util.screen_w, h_util.screen_h = TheSim:GetScreenSize()

local rate_w, rate_h = h_util.screen_w / 1920, h_util.screen_h / 1080
h_util.btn_size = 50 * rate_w


local function checkAtlas(xml, tex)
    xml = xml and resolvefilepath_soft(xml) or xml
    return xml and TheSim:AtlasContains(xml, tex) and xml
end

function h_util:ToRate(x)
    return x * rate_w
end
function h_util:ToSize(x, y)
    return x * rate_w, y * rate_h
end
function h_util:ToPos(a, b)
    local w, h = TheSim:GetScreenSize()
    return a * w, b * h
end

function h_util:AddXmlPath(path)
    t_util:Add(h_util.xml_path, path)
end



function h_util:ActivateUIDraggable(UI, func_stop, UI_follow)
    local pos_last = UI:GetPosition()

    UI_follow = UI_follow or UI
    UI_follow.FollowMouse = function(ui)
        if ui.followhandler == nil then
            local cur_pos = TheInput:GetScreenPosition()
            local scale = 1 / UI.parent:GetScale().x
            local ori_pos = pos_last
            ui.followhandler = TheInput:AddMoveHandler(function(x, y)
                pos_last = (Vector3(x, y, 0) - cur_pos) * scale + ori_pos
                UI:SetPosition(pos_last)
                if TheInput:IsControlPressed(CONTROL_CANCEL) or not TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
                    ui:StopFollowMouse()
                end
            end)
        end
    end

    local _OnMouseButton = UI_follow.OnMouseButton
    UI_follow.OnMouseButton = function(ui, press, down, ...)
        local result = _OnMouseButton(ui, press, down, ...)
        if ui.focus then
            if press == MOUSEBUTTON_LEFT then
                if down then
                    pos_last = UI:GetPosition()
                    return ui:FollowMouse()
                else
                    UI_follow:StopFollowMouse()
                    UI:SetPosition(pos_last)
                    if type(func_stop) == "function" then
                        func_stop(pos_last)
                    end
                end
            end
        end
        ui:StopFollowMouse()
        return result
    end
end


function h_util:AddAnonUI(ui)
    local sc = self:GetActiveScreen()
    sc:AddChild(ui)
    return ui
end


function h_util:ActivateBtnScale(UI, size)
    local tp = h_util:GetType(UI)
    size = size or self.btn_size
    if tp == "UIAnim" then
        local scale = size / 60 * 0.2 * rate_w
        UI:SetScale(scale)
    elseif tp == "BUTTON" then
        local x, y = UI:GetSize()
        local nscale = math.min(size * rate_w / x, size * rate_w / y)
        UI:SetNormalScale(nscale)
        UI:SetFocusScale(nscale * 1.2)
    elseif tp == "Image" then
        local x, y = UI:GetSize()
        local nscale = math.min(size / x, size / y)
        UI:SetScale(nscale)
        UI:SetOnGainFocus(function()
            UI:SetScale(nscale * 1.2)
        end)
        UI:SetOnLoseFocus(function()
            UI:SetScale(nscale)
        end)
    end
end


local scrolls = {MOUSEBUTTON_SCROLLUP, MOUSEBUTTON_SCROLLDOWN}

function h_util:BindMouseClick(UI, data, meta)
    local time_press = 0
    local meta = meta or {}
    local _OnMouseButton = UI.OnMouseButton
    UI.OnMouseButton = function(UI, btn, down, ...)
        if not table.contains(scrolls, btn) then
            if down then
                time_press = os.clock()
                if btn == MOUSEBUTTON_LEFT then
                    
                    if meta.sound ~= "mute" then
                        h_util:PlaySound("click_object")
                    end
                elseif btn == MOUSEBUTTON_RIGHT then
                    
                    if meta.sound == "double" then
                        h_util:PlaySound("click_object")
                    end
                end
            else
                if os.clock() - time_press < h_util.doubleclicktime and type(data[btn]) == "function" then
                    if data[btn](UI) then
                        return true
                    end
                end
            end
        elseif type(data[btn]) == "function" then
            if data[btn](UI) then
                return true
            end
        end
        return _OnMouseButton(UI, btn, down, ...)
    end

    if t_util:GetElement(data, function(btn)
        return table.contains(scrolls, btn)
    end) and TheCamera then
        self:DisableZoom(UI)
    end
end



function h_util:DisableZoom(UI)
    local _ZoomIn = TheCamera.ZoomIn
    TheCamera.ZoomIn = function(...)
        return self:IsValid(UI) and UI.focus or _ZoomIn(...)
    end
    local _ZoomOut = TheCamera.ZoomOut
    TheCamera.ZoomOut = function(...)
        return self:IsValid(UI) and UI.focus or _ZoomOut(...)
    end
end


function h_util:CreateLabel(target, text, offset, font, size, colour)
    return ThePlayer and ThePlayer.HUD and ThePlayer.HUD:AddChild(Label(target, text, offset, font, size, colour))
end

function h_util:AddText(ent, text, offset_y, font, size, color)
    local valid = type(ent) == "table" and ent.entity and ent.prefab and ent:IsValid() and ent.Transform
    if not valid then
        return
    end
    local label = ent.entity:AddLabel()
    label:SetFont(font or CHATFONT_OUTLINE)
    label:SetFontSize(size or 35)
    label:SetWorldOffset(0, offset_y or 3, 0)
    label:SetText(text or "")
    label:SetColour(unpack(self:GetRGB(color)))
    label:Enable(text and true or false)
end

function h_util:SetUIPosition(ui, pos)
    if type(pos) == "table" and (pos[1] or pos.x) then
        ui:SetPosition(Vector3(pos[1] or pos.x, pos[2] or pos.y or 0))
    end
end




function h_util:CreateImageButton(info)
    
    local xml, tex = info.xml, info.tex
    if self:GetPrefabAsset(info.prefab) then
        xml, tex = self:GetPrefabAsset(info.prefab)
    end
    
    local sizes =
        (type(info.size) == "table" and info.size) or (type(info.size) == "number" and {info.size, info.size}) or
            {60, 60}
    local btn = TEMPLATES.StandardButton(nil, nil, sizes, {xml, tex})
    
    if info.hover then
        btn:SetHoverText(info.hover, info.hover_meta and info.hover_meta or {
            offset_y = -sizes[1]
        })
    end
    
    self:SetUIPosition(btn, info.pos)
    
    if info.fn then
        btn:SetOnClick(function()
            info.fn(btn)
        end)
    end
    return btn
end


function h_util:GetSpiceHover(prefab)
    local spice_start = prefab:find("_spice_")
    local xml_hover, tex_hover
    if spice_start then
        local prefab_spice = prefab:sub(spice_start+1, -1).."_over"
        xml_hover, tex_hover = self:GetPrefabAsset(prefab_spice)
        if xml_hover then
            return xml_hover, tex_hover
        else
            
            local xml_spice = t_util:IGetElement(t_util:GetRecur(Prefabs, prefab..".assets") or {},function(asset)
                return asset.type == "ATLAS" and asset.file
            end)
            local prefab_spice = xml_spice and xml_spice:match("images/(.-)%.xml")
            local tex_spice = prefab_spice and prefab_spice..".tex"
            if tex_spice and checkAtlas(xml_spice, tex_spice) then
                return xml_spice, tex_spice
            end
        end
    elseif prefab:sub(-7) == "spawner" then
        return "images/hx_icons1.xml", "spawner_over.tex"
    else
        local set_data = r_data.spice_set[prefab]
        if set_data then
            return set_data[1], set_data[2]
        end
    end
        
end






function h_util:CreatePrefabButton(info)
    info = info or {}
    local bg_data = self.style.imgbtn[info.style_imgbtn or ""] or self.style.imgbtn.default
    local w = ImageButton(unpack(bg_data))
    if info.noclick then
        w:Disable()
    end
    local btn_size = info.size or self.prefab_size
    w:ForceImageSize(btn_size, btn_size)
    w.scale_on_focus = false

    
    w.SetPrefabIcon = function(meta)
        
        t_util:IPairs({"img_main", "text_main", "img_hover"}, function(k)
            if self:IsValid(w[k]) then
                w[k]:Kill()
            end
        end)
        
        meta = meta or {}
        local xml, tex = meta.xml, meta.tex
        if not xml then
            xml, tex = self:GetPrefabAsset(meta.prefab)
        end
        local size_set = meta.size or info.size or self.prefab_size
        if xml then
            
            
            local rate = xml:find("scrapbook_icons") and .9 or (meta.scale or .6)
            size_set = size_set * rate
            w.img_main = w:AddChild(Image(xml, tex))
            w.img_main:ScaleToSize(size_set, size_set)
            
            local xml_hover, tex_hover = self:GetSpiceHover(meta.prefab)
            
            if xml_hover then
                w.img_hover = w:AddChild(Image(xml_hover, tex_hover))
                w.img_hover:ScaleToSize(btn_size, btn_size)
            end
        elseif type(meta.name)=="string" then
            
            w.text_main = w:AddChild(Text(BODYTEXTFONT, size_set*.5, ""))
            
            
            
            w.text_main:SetMultilineTruncatedString(meta.name, 2, size_set*.8, 8, "..")
        end
    end
    return w
end





function h_util:CreateTextEdit(info)
    info = info or {}
    local text_hover = info.hover or STRINGS.UI.SERVERCREATIONSCREEN.SEARCH
    local text_prompt = info.prompt or STRINGS.UI.SERVERCREATIONSCREEN.SEARCH
    local box_width, box_height = info.width or 430, info.height or 60
    local font_size = info.font_size or 50
    local w = TEMPLATES.StandardSingleLineTextEntry(info.fieldtext , box_width, box_height, nil,
        font_size, text_prompt)

    w:SetHoverText(text_hover, {
        offset_y = box_height
    })
    local tb = w.textbox
    
    tb:EnableWordWrap(false)
    tb:EnableScrollEditWindow(true)
    tb.prompt:SetHAlign(ANCHOR_MIDDLE)
    tb.OnTextInputted = info.fn and function(down)
        if down then
            info.fn()
        end
    end or nil
    
    
    tb.OnTextEntered = info.fn_enter and function(str)
        info.fn_enter(str)
    end or nil

    w.focus_forward = tb
    self:SetUIPosition(w, info.pos)
    w.SetString = function(ui, ...)
        return tb:SetString(...)
    end
    w.GetString = function(ui, ...)
        return tb:GetString(...)
    end
    return w
end

local function PopFunc()
    TheFrontEnd:PopScreen()
end


function h_util:CreatePressScreen(title, currentkey, defaultkey, allowmid, options, fn_modsave)
    local format_string = "【%s】需要绑定键盘按键！ \n\n 当前：[%s]  默认：[%s]"
    local body_text = format_string:format(title, currentkey, defaultkey)

    local btns = {{
        text = STRINGS.UI.CONTROLSSCREEN.CANCEL,
        cb = PopFunc
    }, {
        text = "绑定默认[" .. defaultkey .. "]",
        cb = function()
            fn_modsave(nil, "默认：" .. defaultkey)
            PopFunc()
        end
    }, {
        text = STRINGS.UI.CONTROLSSCREEN.UNBIND,
        cb = function()
            local popup_in = PopupDialogScreen("󰀐:警告",
                "取消绑定的话，该操作会写入模组设置。\n 重启游戏后，下次启用就需要从模组设置中手动打开了。",
                {{
                    text = STRINGS.UI.CONTROLSSCREEN.CANCEL,
                    cb = PopFunc
                }, {
                    text = "我确定" .. STRINGS.UI.CONTROLSSCREEN.UNBIND,
                    cb = function()
                        fn_modsave(false, "已禁用")
                        PopFunc()
                        PopFunc()
                    end
                }})
            TheFrontEnd:PushScreen(popup_in)
        end
    }}

    if allowmid then
        table.insert(btns, {
            text = "绑定到功能面板",
            cb = function()
                fn_modsave("biubiu", "功能面板")
                PopFunc()
            end
        })
    end
    local popup = PopupDialogScreen(title, body_text, btns)

    popup.OnRawKey = function(_, key, down)
        if down then
            return
        end
        local pressdata = t_util:IGetElement(options, function(opt)
            return opt.data == key and {
                data = opt.data,
                description = opt.description
            }
        end)
        if pressdata then
            fn_modsave(pressdata.data, pressdata.description)
            h_util:PlaySound("click_move")
            PopFunc()
        else
            h_util:PlaySound("click_negative")
        end
    end
    TheFrontEnd:PushScreen(popup)
end


function h_util:CreatePopupWithClose(title, bodytext, btns, meta)
    local btns = t_util:IPairFilter(btns or {{
        text = h_util.ok
    }}, function(btn)
        return type(btn.text) == "string" and {
            text = btn.text,
            cb = function()
                if type(btn.cb) == "function" then
                    btn.cb()
                end
                if not btn.dontpop then
                    PopFunc()
                end
            end
        }
    end)
    title = title or Mod_ShroomMilk.Mod["春"].name
    meta = c_util:FormatDefault(meta, "table")
    local popup = PopupDialogScreen(title, bodytext, btns, meta.spacing, meta.longness, meta.style)
    TheFrontEnd:PushScreen(popup)
end


function h_util:CreateWriteWithClose(title, info)
    local w_screen = require "screens/huxi/writescreen"
    local screen = w_screen(title, info)
    TheFrontEnd:PushScreen(screen)
    return screen
end




local ImageData = {}
local AvatarData = {}


function h_util:RegisterIcon_MODCHARACTERLIST(prefab, modname)
    local avatar_name = "modavatar_"..modname..prefab
    if not AvatarData[avatar_name] then
        
        
        local path1 = MODS_ROOT .. modname .. "/images/saveslot_portraits/" .. prefab .. ".xml"
        
        local path2 = MODS_ROOT .. modname .. "/images/avatars/avatar_" .. prefab .. ".xml"
        local xml, tex
        
        
        
        
        if kleifileexists(path1) then
            xml = path1
            tex = prefab..".tex"
        elseif kleifileexists(path2) then
            xml = path2
            tex = "avatar_" .. prefab..".tex"
        end
        if xml then
            local pref = Prefab(avatar_name, nil, {Asset("ATLAS", xml)}, nil, true)
            RegisterSinglePrefab(pref)
            TheSim:LoadPrefabs({pref.name})
        end
        AvatarData[avatar_name] = {xml = xml, tex = tex}
    end
    return AvatarData[avatar_name].xml, AvatarData[avatar_name].tex
end

local AtlasData
function h_util:RegisterIcon_ModAtlas()
    if not AtlasData then
        AtlasData = {}
        t_util:IPairs(i_util:GetModsToLoad(), function(modname)
            local mod = ModManager:GetMod(modname) or {}
            local modinfo = mod.modinfo or {}
            local name = modinfo.name or modname
            local xml, tex = modinfo.icon_atlas, modinfo.icon
            if not AtlasData[modname] then
                AtlasData[modname] = {name = name}
            end
            if type(xml)=="string" and type(tex)=="string" then
                local avatar_name = "modatlas_"..modname
                local pref = Prefab(avatar_name, nil, {Asset("ATLAS", xml)}, nil, true)
                RegisterSinglePrefab(pref)
                TheSim:LoadPrefabs({pref.name})
                AtlasData[modname].xml = xml
                AtlasData[modname].tex = tex
            end
        end)
    end
    return AtlasData
end

function h_util:GetModAsset(modname)
    return modname and self:RegisterIcon_ModAtlas()[modname] or {}
end


function h_util:GetImageAsset(prefab)
    local tex = prefab .. ".tex"
    local xml = GetInventoryItemAtlas(tex)
    local atlas = checkAtlas(xml, tex)
    if atlas then
        return atlas, tex
    end
    local rtex = t_util:GetRecur(AllRecipes, prefab..".image")
    if rtex then
        xml = t_util:GetRecur(AllRecipes, prefab..".atlas") or GetInventoryItemAtlas(rtex)
        atlas = checkAtlas(xml, rtex)
        if atlas then
            return atlas, rtex
        end
    end
    for _, path in ipairs(h_util.xml_path) do
        atlas = checkAtlas("images/" .. path, tex)
        if atlas then
            return atlas, tex
        end
    end

    local png = prefab .. ".png"
    for _, path in ipairs(h_util.minimap_path) do
        atlas = checkAtlas(path, png)
        if atlas then
            return atlas, png
        end
    end

    local p_data = Prefabs[prefab]
    if p_data then
        
        if table.contains(MODCHARACTERLIST or {}, prefab) then
            for _, modname in ipairs(i_util:GetModsToLoad()) do
                local alt, img = self:RegisterIcon_MODCHARACTERLIST(prefab, modname)
                if alt then
                    return alt, img
                end
            end
        end
        
        local spice_start = prefab:find("_spice_")
        if spice_start then
            local baseprefab = prefab:sub(1, spice_start - 1)
            if baseprefab then
                return self:GetImageAsset(baseprefab)
            end
        end

        
        local p_assets = p_data.assets
        for _, asset in ipairs(p_assets) do
            local alt, img = xml, tex
            if asset.type == "INV_IMAGE" then
                img = asset.file .. '.tex'
                alt = GetInventoryItemAtlas(img)
            elseif asset.type == "ATLAS" then
                alt = asset.file
            elseif asset.type == "IMAGE" then
                img = asset.file
                img = string.reverse(img:reverse():sub(1, string.find(img:reverse(), "/") - 1))
                alt = t_util:GetElement(p_assets, function(_, asset)
                    return asset.type == "ATLAS" and asset.file
                end)
            end
            atlas = checkAtlas(alt, img)
            if atlas then
                return atlas, img
            elseif asset.type == "INV_IMAGE" then
                img = 'quagmire_' .. asset.file .. '.tex'
                alt = GetInventoryItemAtlas(img)
                atlas = checkAtlas(alt, img)
                if atlas then
                    return atlas, img
                end
            end
        end
    end

    atlas = checkAtlas(GetScrapbookIconAtlas(tex), tex)
    return atlas, atlas and tex
end


function h_util:GetPrefabAsset(prefab, default)
    if not prefab then
        return
    end
    prefab = prefab:gsub("%.tex$", ""):gsub("%.png$", "")
    local ret = ImageData[prefab]
    if not ret then
        local _prefab = r_data.prefab_image[prefab] or prefab
        if _prefab == prefab then
            if prefab:sub(-7) == "_sketch" then
                _prefab = "sketch"
            elseif prefab:sub(-8) == "_spawner" then
                _prefab = prefab:sub(1, prefab:len()-8)
            elseif prefab:sub(-7) == "spawner" then
                _prefab = prefab:sub(1, prefab:len()-7)
            end
        end
        local xml, tex = self:GetImageAsset(_prefab)
        ret = xml and {
            xml = xml,
            tex = tex,
            name = e_util:GetPrefabName(prefab)
        } or {}
        ImageData[prefab] = ret
    end
    if not ret.xml and default then
        return self:GetRandomSkin(true)
    end
    return ret.xml, ret.tex, ret.name
end

local Sounds = {
    learn_map = "dontstarve/HUD/Together_HUD/learn_map",
    research_available = "dontstarve/HUD/research_available",
    click_move = "dontstarve/HUD/click_move",
    click_object = "dontstarve/HUD/click_object",
    click_negative = "dontstarve/HUD/click_negative",
    respec = "wilson_rework/ui/respec",
    research_unlock = "dontstarve/HUD/research_unlock",
    collect_item = "dontstarve/HUD/collect_newitem",
    unweave = "dontstarve/HUD/Together_HUD/collectionscreen/unweave",
}


function h_util:PlaySound(sound)
    sound = Sounds[sound] or sound
    TheFrontEnd:GetSound():PlaySound(sound)
    
end


function h_util:GetRandomSkin(default)
    if type(PREFAB_SKINS) ~= "table" or default then
        return resolvefilepath_soft("modicon.xml"), "modicon.tex"
    end
    local xml, tex
    repeat
        local name, skins = t_util:GetRandomItem(PREFAB_SKINS)
        if name then
            skins = t_util:MergeList(skins)
            table.insert(skins, name)
            local _, skin = t_util:GetRandomItem(skins)
            xml, tex = h_util:GetPrefabAsset(skin)
        end
    until xml
    return xml, tex
end


local widgets_name = {"TextEdit", "UIAnimButton", "ImageButton", "TextButton", "UIAnim", "Text", "Button", "Image", "Screen", "Widget"}
function h_util:GetType(UI)
    local tp = type(UI)
    if tp ~= "table" or not UI.is_a then
        return tp
    end
    return t_util:IGetElement(widgets_name, function(ui_name)
        return UI.is_a(UI, require("widgets/"..ui_name:lower())) and ui_name
    end) or UI
end


function h_util:VisibleUI(UI, show, meta)
    local tp = h_util:GetType(UI)
    if not tp then
        
        return
    elseif tp == "UIAnim" then
        local anim = UI:GetAnimState()
        if show then
            anim:OverrideSymbol(meta[1], meta[2], meta[1])
        else
            anim:OverrideSymbol(meta[1], "hx_trans", "hx_trans")
        end
    elseif tp == "Image" then
        if show then
            UI:SetSize(1, 1)
            UI:SetScaleMode(SCALEMODE_FILLSCREEN)
        else
            UI:SetSize(0, 0)
        end
    end
end


local colour_default = "白色"
local v_data = require("data/valuetable")

local data_rgb = v_data.RGB
function h_util:GetRGB(color, default)
    color = color or default or colour_default
    return data_rgb[color] or data_rgb[colour_default]
end

local wcolour_default = "蓝色"
local data_wrgb = v_data.WRGB
function h_util:GetWRGB(color, default)
    color = color or default or wcolour_default
    return data_wrgb[color] or data_wrgb[wcolour_default]
end


function h_util.SetColor(UI, color)
    color = h_util:GetWRGB(color)
    UI.AnimState:SetMultColour(unpack(color))
    UI.AnimState:SetAddColour(unpack(color))
    return UI
end
function h_util.SetAddColor(UI, color)
    if UI and UI.AnimState then
        if color then
            color = h_util:GetRGB(color)
            UI.AnimState:SetAddColour(unpack(color))
        else
            UI.AnimState:SetAddColour(0, 0, 0, 0)
        end
    end
end

function h_util.SetVisable(UI, bool)
    if bool then
        UI:Show()
    else
        UI:Hide()
    end
    return UI
end


function h_util:GetControls()
    return h_util:GetHUD().controls or {}
end


function h_util:GetHUD()
    return ThePlayer and ThePlayer.HUD or {}
end


function h_util:GetActiveScreen(name)
    local screens = TheFrontEnd.screenstack or {}
    if name then
        return t_util:IGetElement(table.reverse(screens), function(screen)
            return screen.name == name and screen
        end)
    end
    local count = #screens
    if count > 1 then
        return tostring(screens[count]) == "ConsoleScreen" and screens[count - 1] or screens[count]
    end
    return TheFrontEnd:GetActiveScreen() or {}
end


function h_util:CtrlBoard()
    local board = h_util:GetControls().mboard or h_util:GetActiveScreen().mboard
    if not board then
        return
    end
    if board:IsVisible() then
        board:Hide()
    else
        board:Show()
    end
end

function h_util:GetShowScreen()
    return self:GetActiveScreen("ShowScreen")
end


function h_util:GetLines()
    return (self:GetShowScreen() or {}).lines
end


function h_util:GetHicon()
    return h_util:GetControls().hicon or t_util:IGetElement(TheFrontEnd.screenstack, function(screen)
        return screen.hicon
    end)
end


function h_util:GetECtrl()
    return t_util:GetRecur(h_util:GetControls(), "inv.ectrl")
end


function h_util:GetCB()
    return self:GetHUD().hx_cb
end


function h_util:GetTimer()
    return t_util:GetRecur(ThePlayer, "HUD.controls.hx_timer")
end

function h_util:GetHMaps()
    local screens = TheFrontEnd.screenstack or {}
    return t_util:IPairFilter(screens, function(screen)
        return screen and screen.hx_map
    end)
end


function h_util:GetStringKeyBoardMouse(keycode)
    local inputs = t_util:GetRecur(STRINGS, "UI.CONTROLSSCREEN.INPUTS") or {}
    return inputs[1] and keycode and inputs[1][keycode]
end


local zipxmls, unzipxmls = {}, {}
for i = 1, 3 do
    zipxmls["images/inventoryimages" .. i .. ".xml"] = i .. "zip"
    unzipxmls[i .. 'zip'] = "images/inventoryimages" .. i .. ".xml"
end
function h_util:ZipXml(xml, unzip)
    local xmls = unzip and unzipxmls or zipxmls
    return xml and xmls[xml] or xml
end


local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2
local reso_w, reso_h = h_util.screen_w / RESOLUTION_X, h_util.screen_h / RESOLUTION_Y
function h_util:WorldPosToMinimapPos(x, z)
    
    local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    
    return ((map_x * half_x) + half_x) * reso_w, ((map_y * half_y) + half_y) * reso_h
end

function h_util:WorldPosToScreenPos(x, z)
    return TheSim:GetScreenPos(x, 0, z)
end


function h_util:ScreenPosToWorldPos(x, y)
    return TheSim:ProjectScreenPos(x, y)
end


function h_util:SetMouseSecond()
    return {{
        data = MOUSEBUTTON_RIGHT,
        description = "鼠标右键 " .. self:GetStringKeyBoardMouse(MOUSEBUTTON_RIGHT)
    }, {
        data = MOUSEBUTTON_MIDDLE,
        description = "鼠标中键 " .. self:GetStringKeyBoardMouse(MOUSEBUTTON_MIDDLE)
    }, {
        data = 1006,
        description = "侧键1 " .. self:GetStringKeyBoardMouse(1006)
    }, {
        data = 1005,
        description = "侧键2 " .. self:GetStringKeyBoardMouse(1005)
    }, {
        data = MOUSEBUTTON_SCROLLUP,
        description = "上滚轮 " .. self:GetStringKeyBoardMouse(MOUSEBUTTON_SCROLLUP)
    }, {
        data = MOUSEBUTTON_SCROLLDOWN,
        description = "下滚轮 " .. self:GetStringKeyBoardMouse(MOUSEBUTTON_SCROLLDOWN)
    }, {
        data = h_util.cancel,
        description = "取消绑定"
    }}
end


function h_util:IsValid(ui)
    return ui and ui.inst and ui.inst.widget 
end

local xml_scrap = "images/scrapbook.xml"

function h_util:SpawnScrapBookImage(width, height)
    local ratio = width / height
    local suffix = "_square"
    if ratio > 5 then
        suffix = "_thin"
    elseif ratio > 1 then
        suffix = "_wide"
    elseif ratio < 0.75 then
        suffix = "_tall"
    end

    local materials = {"scrap", "scrap2"}
    local tex = materials[math.ceil(math.random() * #materials)] .. suffix .. ".tex"
    local img = Image(xml_scrap, tex)
    img:ScaleToSize(width, height)
    return img
end




function h_util:BuildGrid_PrefabButton(c_tor)
    local cell_size = c_tor.cell_size or 70 
    local cell_spacing = c_tor.cell_spacing or .6 
    local font_size = c_tor.font_size or 40 
    local line, col = c_tor.line or 4, c_tor.col or 6
    local boarder_scale = .8
    local c_tor = c_util:FormatDefault(c_tor, "table")
    local context = c_tor.context or {}
    local grid

    local function ScrollWidgetsCtor(_, index)
        local w = self:CreatePrefabButton({
            id = "grid_cell_" .. index,
            size = cell_size,
            style_imgbtn = c_tor.style_imgbtn,
        })

        local _OnMouseButton = w.OnMouseButton
        w.OnMouseButton = function(ui, btn, down, ...)
            
            if btn == MOUSEBUTTON_RIGHT and not down then
                local parent = grid and self:IsValid(grid:GetParent())
                if parent and w.fn_rr then
                    w.fn_rr(parent, grid, ...)
                end
            
            elseif btn == MOUSEBUTTON_LEFT and down and w.fn_sel then
                w.fn_sel()
            elseif btn == MOUSEBUTTON_MIDDLE and down and w.fn_mid then
                local parent = grid and self:IsValid(grid:GetParent())
                if parent and w.fn_mid then
                    w.fn_mid(parent, grid, ...)
                end
            end
            return _OnMouseButton(ui, btn, down, ...)
        end
        return w
    end
    local function fn_sel(prefab, data)
        return function()
            if c_tor.fn_sel then
                local parent = grid and self:IsValid(grid:GetParent())
                if parent then
                    c_tor.fn_sel(prefab, parent, grid, context, data)
                end
            else
                context.prefab = prefab ~= context.prefab and prefab or nil
                if grid then
                    grid:RefreshView() 
                end
            end
        end
    end
    local function ScrollWidgetSetData(context, w, data)
        if data then
            w.SetPrefabIcon(data)
            if type(data.hover) == "string" then
                w:SetHoverText(data.hover, {
                    offset_y = data.hover:find("\n") and 2*cell_size or 1.5*cell_size
                })
            end
            
            if c_tor.ensel then
                local bg_data = self.style.imgbtn[c_tor.style_imgbtn or ""] or self.style.imgbtn.default
                local atlas, normal, focus, focus_sel, _, selected = unpack(bg_data)
                if data.prefab == context.prefab then
                    if selected and focus_sel then
                        w:SetTextures(atlas, selected, focus_sel)
                    end
                else
                    w:SetTextures(atlas, normal, focus)
                end
            end
            
            if not c_tor.nosale then
                if w.tag_sale then
                    w.tag_sale:Kill()
                end
                if data.prefab == context.prefab then
                    w.tag_sale = w:AddChild(Image("images/global_redux.xml", "shop_sale_tag.tex"))
                    w.tag_sale:ScaleToSize(cell_size*.8, cell_size*.8)
                    w.tag_sale:SetPosition(cell_size*.2, cell_size*.2)
                end
            end
            
            w.fn_sel = fn_sel(data.prefab, data)
            
            w.fn_rr = c_tor.fn_rr and function(parent, grid, ...)
                c_tor.fn_rr(data.prefab, parent, grid, context, data, ...)
            end
            w.fn_mid = c_tor.fn_mid and function(parent, grid, ...)
                c_tor.fn_mid(data.prefab, parent, grid, context, data, ...)
            end
            w:Show()
        else
            w:Hide()
        end
    end
    grid = TEMPLATES.ScrollingGrid({}, {
        scroll_context = context,
        widget_width = cell_size + cell_spacing, 
        widget_height = cell_size + cell_spacing, 
        num_visible_rows = line, 
        num_columns = col, 
        item_ctor_fn = ScrollWidgetsCtor, 
        apply_fn = ScrollWidgetSetData, 
        scrollbar_offset = c_tor.scrollbar_offset or 20, 
        scrollbar_height_offset = c_tor.scrollbar_height_offset, 
        force_peek = c_tor.force_peek,
        peek_height = c_tor.peek_height,
        peek_percent = c_tor.peek_percent,
    })

    
    grid.SetScrollBarStyle = function(ui, style_name)
        local function fn_style(style)
            local function fn_settextures(img, xml, tex)
                if xml and tex and img then
                    if img.SetTextures then
                        img:SetTextures(xml, tex)
                    elseif img.SetTexture then
                        img:SetTexture(xml, tex)
                    end
                end 
            end
            fn_settextures(ui.up_button, style.atlas, style.up)
            fn_settextures(ui.down_button, style.atlas, style.down)
            fn_settextures(ui.scroll_bar_line, style.atlas, style.bar)
            fn_settextures(ui.position_marker, style.atlas, style.handle)
            fn_settextures(ui.position_marker.image, style.atlas, style.handle)
        end
        local style = style_name and self.style.scrollbar[style_name]
        if style then
            fn_style(style)
            if style_name == "light" then
                ui.up_button:SetScale(.5)
                ui.down_button:SetScale(.5)
                ui.scroll_bar_line:SetTexture("images/hx_long.xml", "scrollbar_bar.tex")
            end
        else
            fn_style(self.style.scrollbar.default)
            ui.up_button:SetScale(0.5)
            ui.down_button:SetScale(-0.5)
            ui.scroll_bar_line:SetScale(.8)
            ui.position_marker:SetScale(.6)
        end
    end
    grid:SetScrollBarStyle(c_tor.style_scr)

    
    if c_tor.scroll_bar_show then
        grid.CanScroll = function()
            return true
        end
        
        grid.scroll_bar_container:Show()
    end

    
    local grid_w, grid_h = grid:GetScrollRegionSize()
    local name_border = c_tor.style_border
    local style_border = name_border and self.style.border[name_border] or self.style.border.default

    if not c_tor.noborderup then
        grid.gb_up = grid:AddChild(Image(unpack(style_border)))
        grid.gb_up:SetScale(boarder_scale, boarder_scale)
        grid.gb_up:SetPosition(-3, grid_h / 2)  
    end
    if not c_tor.noborderdown then
        grid.gb_down = grid:AddChild(Image(unpack(style_border)))
        grid.gb_down:SetScale(boarder_scale, -boarder_scale)
        grid.gb_down:SetPosition(-3, -grid_h / 2 - 1)
    end

    local grid_text = grid:AddChild(Text(HEADERFONT, font_size, "", UICOLOURS.BROWN_DARK))
    
    local _SetItemsData = grid.SetItemsData
    grid.SetItemsData = function(ui, ...)
        _SetItemsData(ui, ...)

        if #ui.items == 0 then
            if type(c_tor.zero_show)=="string" then
                grid_text:SetString(c_tor.zero_show)
            else
                grid_text:SetString("共搜索到 0 个结果")
            end
            if c_tor.zero_color then
                grid_text:SetColour(c_tor.zero_color)
            end
        else
            grid_text:SetString("")
        end
    end
    
    grid:SetPosition(-145, -70)

    
    grid.OnFocusMove = function() return false end
    if c_tor.nozoom then
        self:DisableZoom(grid)
    end

    return grid
end


function h_util:BuildGrid_PrefabDetail()
    local w = Widget("grid_detail")
    w.icon_show = w:AddChild(self:CreatePrefabButton({
        style_imgbtn = "ui",
        noclick = true,
        size = 175
    }))
    w.text_show = w:AddChild(Text(NEWFONT, 40, "", UICOLOURS.BLACK))
    w.text_show:SetPosition(0, -145)
    return w
end


function h_util:NinesliceTop(width, height)
    local w = Widget("nineslice_top")
    w.top = w:AddChild(Image(xml_slice, "crown_top_fg.tex"))
    w.mid = w:AddChild(Image(xml_slice, "top.tex"))
    w.left = w:AddChild(Image(xml_slice, "topleft.tex"))
    w.right = w:AddChild(Image(xml_slice, "topright.tex"))

    w.top:SetSize(width/2, height)
    w.mid:SetSize(width, height/3)
    w.left:SetSize(height, height)
    w.right:SetSize(height, height)

    w.left:SetPosition(-width / 2 - height / 2, 0)
    w.right:SetPosition(width / 2 + height / 2, 0)
    w.mid:SetPosition(0, -height/3)
    return w
end




function h_util:BuildFrame(width, height)
    local w = Widget("huxi_menu_frame")
    local atlas = resolvefilepath(CRAFTING_ATLAS)
    
    w.fill = w:AddChild(Image(atlas, "backing.tex"))
    w.fill:ScaleToSize(width + 10, height + 18)
    w.fill:SetTint(1, 1, 1, 0.3)

    
    w.left = w:AddChild(Image(atlas, "side.tex"))
    w.right = w:AddChild(Image(atlas, "side.tex"))
    w.top = w:AddChild(Image(atlas, "top.tex"))
    w.bottom = w:AddChild(Image(atlas, "bottom.tex"))

    w.left:SetPosition(-width / 2 - 8, 1)
    w.right:SetPosition(width / 2 + 8, 1)
    w.top:SetPosition(0, height / 2 + 10)
    w.bottom:SetPosition(0, -height / 2 - 8)

    w.left:ScaleToSize(-26, -(height - 20))
    w.right:ScaleToSize(26, height - 20)
    w.top:ScaleToSize(width+33, 38)
    w.bottom:ScaleToSize(width+33, 38)

    return w
end

function h_util:IsInvXml(xml)
    return xml and (xml:find("inventoryimages.xml") or xml:find("inventoryimages1.xml") or xml:find("inventoryimages2.xml") or xml:find("inventoryimages3.xml"))
end

function h_util:FocusTwoline(strline)
    
    local ui = self:GetCB()
    if self:IsValid(ui) then
        ui:Hide()
    end
    ThePlayer.HUD:Hide()
    ThePlayer.HUD.under_root:Hide()
    if not self:IsValid(ThePlayer.HUD.twolines) then
        
        ThePlayer.HUD.twolines = ThePlayer.HUD:AddChild(TwoLines(strline))
        ThePlayer.HUD.twolines:SetPosition(0, self.screen_h * -.075)
    end
end




function h_util:debug_pos(ui)
    if self:IsValid(ui) then
        self:ActivateUIDraggable(ui, function(pos)
            print("debug_pos", pos)
        end)
        t_util:JoinDebug(ui, "ui")
    end
end

return h_util
