local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local xml_quag = "images/quagmire_recipebook.xml"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local m_util = require "util/modutil"
local c_util = require "util/calcutil"






local ScreenScreen = Class(Screen, function(self, screen_data)
    Screen._ctor(self, "ShowScreen")
    self.w, self.h = 800, 500
    self.font_size = 35
    
    
    self:PaintRoot()
    self:PaintScreen(screen_data)
end)



function ScreenScreen:PaintScreen(screen_data)
    self.screen_data = m_util:HookShowScreenData(c_util:FormatDefault(screen_data, "table"))
    self.value = {} 
    self.page = 1
    self:PaintIcon()
    self:PaintTop() 
    
    local function fn_linebuilt()
        local fn = self.screen_data.fn_line or function()end
        fn(self.lines, self)
    end
    local fn_data = self["Make_"..(self.screen_data.type or "ten")] 
    self.PaintData = type(fn_data) == "function" and function()
        fn_data(self)
        fn_linebuilt()
    end or fn_linebuilt
    
    if not self.screen_data.fn_active then
        self:PaintData() 
    end
end

function ScreenScreen:PaintTop()
    if self.title then self.title:Kill() end
    if not self.screen_data.title then return end
    self.title = self.root:AddChild(Text(HEADERFONT, self.font_size, self.screen_data.title, UICOLOURS.BLACK))
    self.title:SetPosition(0, self.h / 2 - self.font_size)
    self.title_line = self.title:AddChild(Image(xml_quag, "quagmire_recipe_line_break.tex"))
    self.title_line:SetPosition(0, -self.font_size+5)
    self.arr_l = self.title:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil,
        nil, nil, { 1, 1 }, { 0, 0 }))
    self.arr_r = self.title:AddChild(ImageButton("images/frontend.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil,
        nil, nil, { 1, 1 }, { 0, 0 }))
    self.arr_l:SetPosition(-self.w / 5.5, 0)
    self.arr_l:SetScale(1, .4, .6)
    self.arr_r:SetPosition(self.w / 5.5, 0)
    self.arr_r:SetScale(-1, .4, .6)
    self.arr_r:SetHoverText("下一页")
    self.arr_l:SetHoverText("上一页")
    self.arr_l:SetOnClick(function()
        self.page = self.page - 1
        self:PaintData()
    end)
    self.arr_r:SetOnClick(function()
        self.page = self.page + 1
        self:PaintData()
    end)
    self.arr_l:Hide()
    self.arr_r:Hide()
end

function ScreenScreen:PaintRoot()
    local black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    black:SetOnClick(function() TheFrontEnd:PopScreen() end)
    local bg = black.image
    bg:SetVAnchor(ANCHOR_MIDDLE) 
    bg:SetHAnchor(ANCHOR_MIDDLE)
    bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    bg:SetTint(0, 0, 0, 0) 
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.book = self.root:AddChild(Image(xml_quag, "quagmire_recipe_menu_bg.tex"))
    self.book:SetSize(self.w, self.h)
end

local sizes_default = {60, 55, 50}
local btn_pos_data = {
    right11 = {250, 170},
    right21 = {235, 170},
    right22 = {295, 170},
    right31 = {215, 170},
    right32 = {270, 170},
    right33 = {325, 170},
}

function ScreenScreen:PaintIcon()
    if self.icons then self.icons:Kill() end
    self.icons = self.root:AddChild(Widget("icons"))
    local icons = c_util:FormatDefault(self.screen_data.icon, "table")
    icons = icons.id and {icons} or icons       
    local num_icons = #icons
    local size_default = sizes_default[num_icons] or 60

    local text_help = self.screen_data.help
    if type(text_help) == "string" then
        self.icons.btn_help = self.icons:AddChild(h_util:CreateImageButton({
            prefab = "cookbook_missing",
            fn = function()
                local title_help = self.screen_data.title_help
                local title_str = self.screen_data.title and self.screen_data.title.."·提示" or "功能提示"
                if type(title_help) == "string" then
                    title_str = title_help
                end
                h_util:CreatePopupWithClose(title_str, text_help)
            end,
            hover = "功能提示",
            pos = {-btn_pos_data.right11[1], btn_pos_data.right11[2]}
        }))
    end

    t_util:Pairs(icons, function(num, info)
        if not (info.id and type(num) == "number") then return end
        info.size = info.size or size_default
        local pos_default = btn_pos_data["right"..num_icons..num] or btn_pos_data.right11
        local pos_info = type(info.pos) == "string" and btn_pos_data[info.pos]
        info.pos = pos_info or info.pos or pos_default
        self.icons[info.id] = self.icons:AddChild(h_util:CreateImageButton(info, self.icons))
    end)
end

function ScreenScreen:UpdatePage(num)
    self.data = c_util:FormatDefault(self.screen_data.data, "table")
    self.num = num or self.num
    if self.arr_l and self.arr_r and self.num then
        self.arr_l:Show()
        self.arr_r:Show()
        local page = self.page
        if page <= 1 then
            self.arr_l:Hide()
        end
        local page_max = math.ceil(#self.data / self.num)
        if page >= page_max then
            self.arr_r:Hide()
        end
    end
    if self.lines then self.lines:Kill() end
    self.lines = self.root:AddChild(Widget("lines"))
end

function ScreenScreen:PaintData()
    
    
end




function ScreenScreen:LoadDefault(b_data, value)
    local screen_default = self.screen_data.default
    if type(b_data.default) == "function" then
        value = b_data.default(b_data.id)
    elseif type(b_data.default) ~= "nil" then
        value = b_data.default
    elseif type(screen_default) == "function" then
        value = screen_default(b_data.id)
    elseif type(screen_default) ~= "nil" then
        value = screen_default
    end
    self.value[b_data] = value
    return value
end



function ScreenScreen:Make_log()
    self:UpdatePage(1)
    local shift_x = (-0.5+0.12)*self.w
    self.lines:SetPosition(shift_x, (0.5-0.32)*self.h)
    local b_data = self.data[self.page]
    if not b_data then return end
    local widget = self.lines:AddChild(Widget("log"))
    local time = widget:AddChild(Text(HEADERFONT, self.font_size-2, b_data.time, UICOLOURS.BLACK))
    local content = widget:AddChild(Text(HEADERFONT, self.font_size-5, b_data.content, UICOLOURS.BROWN_DARK))

    time:SetHAlign(ANCHOR_LEFT)
    content:SetRegionSize(self.w/1.2, self.h)
    content:EnableWordWrap(true)
    content:SetVAlign(ANCHOR_TOP)
    content:SetHAlign(ANCHOR_LEFT)

    time:SetPosition(50, 50)
    content:SetPosition(310, -220)
end

function ScreenScreen:Make_ten()
    self:UpdatePage(10)
    local shift_x = (-0.5+0.12)*self.w
    self.lines:SetPosition(shift_x, (0.5-0.32)*self.h)
    self.bar = self.lines:AddChild(Image(xml_quag, "quagmire_recipe_scroll_bar.tex"))
    self.bar:SetSize(5, 0.626*self.h)
    self.bar:SetPosition(-shift_x, self.h * -0.25)
    for i = 1, self.num do
        local nodot = (self.page - 1) * self.num + i
        local b_data = self.data[nodot]
        if not (b_data and b_data.id) then break end
        self:LoadDefault(b_data)
        local tp = b_data.type or "box"
        local ui_made = self["Ten_"..tp]
        local widget = type(ui_made) == "function" and ui_made(self, b_data)
        if not widget then return end
        self.lines[b_data.id] = self.lines:AddChild(widget)
        widget:SetHoverText(b_data.hover, { font = NEWFONT_OUTLINE, offset_y = 90 })
        widget:SetPosition((i - 1) % 2 * (self.w / 2 - 60), -math.floor((i - 1) / 2) * 70)
    end
end






function ScreenScreen:Make_player()
    self:UpdatePage()
    local data = c_util:FormatDefault(self.screen_data.data_create, "table")
    t_util:IPairs(data, function(info)
        if not info.id then return end
        local fn_ui = info.name and self[info.name] or info.fn
        local ui = type(fn_ui)=="function" and fn_ui(self, info.meta) or Widget(info.id)
        local pui = info.pid and self.lines[info.pid] or self.lines
        pui[info.id] = pui:AddChild(ui)
    end)
end







function ScreenScreen:Ten_dashimg(b_data)
    local w = Widget("dashimg")
    local btn = w:AddChild(TextBtn())
    w.ui_text = btn
    btn:SetFont(HEADERFONT)
    btn:SetTextSize(self.font_size - 2)
    local _width = 0.28*self.w

    local line = btn:AddChild(Image("images/hx_long2.xml", "scrollbar_line.tex"))
    line:SetSize(5, _width)
    line:SetRotation(90)
    line:SetPosition(0, -25)
    function btn.uiSwitch(value)
        local val = value and true or false
        local data = b_data.data[val]
        if data then
            data = type(data) == "table" and data or {label = data}
            local xml, tex = data.xml or b_data.xml, data.tex or b_data.tex
            if not xml then
                xml, tex = h_util:GetPrefabAsset(data.prefab or b_data.prefab)
            end
            w.ui_img:SetTexture(xml, tex)
            h_util:ActivateBtnScale(w.ui_img, 55)
            btn:SetText(data.label)
            local rgb = h_util:GetRGB(data.color or "黑色")
            btn:SetTextColour(rgb)
            local rate = .8
            btn:SetOverColour(rgb[1]*rate, rgb[2]*rate, rgb[3]*rate, rgb[4]*rate)
        end
    end
    function btn.switch(value)
        btn.uiSwitch(value)
        if type(b_data.fn) == "function" then
            b_data.fn(value, self.lines, self.data, self)
        end
    end
    btn:SetOnClick(function()
        self.value[b_data] = not self.value[b_data]
        btn.switch(self.value[b_data])
    end)
    btn:SetPosition(self.w*0.22, 0)

    
    local xml, tex = b_data.xml, b_data.tex
    if not xml then
        xml, tex = h_util:GetPrefabAsset(b_data.prefab)
    end
    w.ui_img = btn:AddChild(Image(xml, tex))
    btn.uiSwitch(self.value[b_data])
    w.ui_img:SetPosition(self.w*-0.21, 0)
    return w
end


function ScreenScreen:Ten_imgstr(b_data)
    local w = Widget("imgstr")
    local btn = w:AddChild(TextBtn())
    w.ui_text = btn
    btn:SetText(b_data.label)
    btn:SetTextColour(UICOLOURS.BROWN_DARK)
    btn:SetFont(HEADERFONT)
    btn:SetTextSize(self.font_size - 2)
    local _width = 0.28*self.w

    local line = btn:AddChild(Image(xml_quag, "quagmire_recipe_scroll_bar.tex"))
    line:SetSize(5, _width)
    line:SetRotation(90)
    line:SetPosition(0, -25)
    function btn.uiSwitch()
    end
    function btn.switch(value)
        btn.uiSwitch(value)
        if type(b_data.fn) == "function" then
            b_data.fn(self.value[b_data], self.lines, self.data, self)
        end
    end
    btn:SetOnClick(function()
        btn.switch()
    end)
    btn:SetPosition(self.w*0.22, 0)

    
    local xml, tex = b_data.xml, b_data.tex
    if not xml then
        xml, tex = h_util:GetPrefabAsset(b_data.prefab)
    end
    local img = btn:AddChild(Image(xml, tex))
    w.ui_img = img
    
    h_util:ActivateBtnScale(img, 55)
    img:SetPosition(self.w*-0.21, 0)
    return w
end

function ScreenScreen:Ten_radio(b_data)
    local btn = Widget("radio")

    btn.text = btn:AddChild(Text(HEADERFONT, self.font_size-2, b_data.label, UICOLOURS.BLACK))
    local width = btn.text:GetRegionSize()
    btn.text:SetPosition(width/2-15, 0)
    
    btn.arr_l = btn:AddChild(ImageButton(xml_quag, "arrow2_left.tex", "arrow2_left_over.tex", "arrow_left_disabled.tex", "arrow2_left_down.tex", nil,{1,1}, {0,0}) )
    btn.arr_r = btn:AddChild(ImageButton(xml_quag, "arrow2_right.tex", "arrow2_right_over.tex", "arrow_right_disabled.tex", "arrow2_right_down.tex", nil,{1,1}, {0,0}) )
    
    local arrow_size = btn.arr_l:GetSize()
    local arrow_scale = 60 / arrow_size
    btn.arr_r:SetNormalScale(arrow_scale)
    btn.arr_r:SetFocusScale(arrow_scale * 1.1)
    btn.arr_l:SetNormalScale(arrow_scale)
    btn.arr_l:SetFocusScale(arrow_scale * 1.1)

    btn.arr_l:SetPosition(self.w*0.15, 0)
    btn.arr_r:SetPosition(self.w*0.36, 0)

    
    local str_show = ""
    btn.showtext = btn:AddChild(Text(HEADERFONT, self.font_size-5, str_show, UICOLOURS.BROWN_MEDIUM))
    btn.showtext:SetPosition(self.w*.255, 0)

    local function getid()
        self.value[b_data] = tostring(self.value[b_data])
        return t_util:GetElement(b_data.data, function(id, info)
            return self.value[b_data] == tostring(info.data) and id
        end) or 1
    end

    local function update_arr(id, onlyui)
        btn.arr_l:Show()
        btn.arr_r:Show()
        if id <= 1 then
            id = 1
            btn.arr_l:Hide()
        elseif id >= #b_data.data then
            id = #b_data.data
            btn.arr_r:Hide()
        end
        if b_data.data[id] then
            self.value[b_data] = b_data.data[id].data
            str_show = b_data.data[id].description
            if self.value[b_data] and str_show then
                btn.showtext:SetString(str_show)
                if not onlyui and type(b_data.fn)=="function" then
                    b_data.fn(self.value[b_data], self.lines, self.data, self)
                end
            end
        end
    end
    update_arr(getid(), true)
    btn.arr_l:SetOnClick(function()
        update_arr(getid() - 1)
    end)
    btn.arr_r:SetOnClick(function()
        update_arr(getid() + 1)
    end)
    function btn.switch(value)
        self.value[b_data] = value
        update_arr(getid())
    end
    function btn.uiSwitch(value)
        self.value[b_data] = value
        update_arr(getid(), true)
    end
    return btn
end

function ScreenScreen:Ten_box(b_data)
    local btn = ImageButton(xml_quag, "cookbook_known.tex")
    local btn_size = btn:GetSize()
    local btn_scale = 60 / btn_size
    btn:SetNormalScale(btn_scale)
    btn:SetFocusScale(btn_scale * 1.2)
    btn.img_or = btn.image:AddChild(Image("images/hx_or.xml", self.value[b_data] and "right.tex" or "wrong.tex"))
    btn.img_or:SetSize(100, 100)
    function btn.uiSwitch(value)
        self.value[b_data] = value
        btn.img_or:SetTexture("images/hx_or.xml", value and "right.tex" or "wrong.tex")
        btn.img_or:SetSize(100, 100)
    end
    function btn.switch(value)
        btn.uiSwitch(value)
        if type(b_data.fn) == "function" then
            b_data.fn(self.value[b_data], self.lines, self.data, self)
        end
    end
    btn:SetOnClick(function()
        btn.switch(not self.value[b_data])
    end)
    btn.labeltext = btn:AddChild(Text(HEADERFONT, self.font_size-2, b_data.label, UICOLOURS.BROWN_DARK))
    btn.labeltext:SetPosition(self.w*.2, 0)
    return btn
end

function ScreenScreen:Ten_textbtn(b_data)
    local w = Widget("textbtn")

    w.text = w:AddChild(Text(HEADERFONT, self.font_size-2, b_data.label, UICOLOURS.BLACK))
    local width = w.text:GetRegionSize()
    w.text:SetPosition(width/2-15, 0)

    local ttn = TextBtn()
    w.showtext = w:AddChild(ttn)
    ttn:SetText(self.value[b_data] or "未设置")
    ttn:SetFont(HEADERFONT)
    ttn:SetTextSize(self.font_size-5)
    ttn:SetColour(UICOLOURS.BROWN_DARK)
    function w.uiSwitch(value)
        self.value[b_data] = value
        ttn:SetText(self.value[b_data] or "未设置")
    end
    function w.switch()
        if type(b_data.fn) == "function" then
            b_data.fn(self.value[b_data], self.lines, self.data, self)
        end
    end
    ttn:SetOnClick(function()
        w.switch()
    end)

    local _width = self.w*.25
    ttn:SetPosition(_width, 0)

    
    local bgimage = ttn:AddChild(Image(xml_quag, "cookbook_known.tex"))
    bgimage:SetSize(_width, 40)
    bgimage:SetTint(0, 0, 0, 0)

    local line = ttn:AddChild(Image(xml_quag, "quagmire_recipe_scroll_bar.tex"))
    line:SetSize(5, _width)
    line:SetRotation(90)
    line:SetPosition(0, -23)


    return w
end


function ScreenScreen:OnControl(control, down)
    if ScreenScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen(self)
        return true
    end
end

function ScreenScreen:OnBecomeActive()
    ScreenScreen._base.OnBecomeActive(self)
    local fn_active = self.screen_data.fn_active
    if fn_active then
        self:PaintData()
        if type(fn_active) == "function" then 
            fn_active(self)
        end
    end
end

return ScreenScreen
