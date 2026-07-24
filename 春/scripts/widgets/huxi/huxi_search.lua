
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"


local c_util, e_util, h_util, m_util, t_util,p_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil",
require "util/playerutil"



local Sch = Class(Widget, function(self, funcs, save_data)
    Widget._ctor(self, "Huxi_Search")
    
    local btn_size = 50
    local search_box_width, search_box_height = btn_size*6, btn_size
    local frame_width, frame_height = search_box_width+2*btn_size, search_box_height*3
    local posx, posy = frame_width/3, frame_height/4
    local print_height = 4*frame_height

    self.Func = funcs
    self.Data = save_data
    self.init_x, self.init_y = h_util.screen_w/4, h_util.screen_h/3*2

    self:SetUIPos()
    self.root = self:AddChild(Widget("root"))

    self.frame = self.root:AddChild(self:MakeFrame(frame_width, frame_height))
    self.frame.fill:SetHoverText(STRINGS.LMB.."可拖拽 \n黏着鼠标请按Esc", {offset_y = -3*btn_size, colour = UICOLOURS.GOLD, font_size = 18})
    h_util:ActivateUIDraggable(self, self.Func.SavePos, self.frame.fill)

    self.search_box = self.frame:AddChild(self:MakeSearchBox(search_box_width, search_box_height))
    self.search_box:SetPosition(-0.5*btn_size, posy)

    self.check_box = self.frame:AddChild(self:MakeCheckBox(2*btn_size, false))
    self.check_box:SetPosition((frame_width-btn_size)/2, posy)

    self.print_text = self.frame:AddChild(self:MakePrintText(btn_size*0.75, frame_width, print_height))
    self.print_text:SetPosition(frame_width+btn_size, -(print_height-frame_height)/2)

    local function GetData()
        local text = self.search_box.textbox_root.textbox:GetString()
        local value = self.check_box.checkbox_value
        return c_util:TrimString(text), value
    end
    self.btn_close = self.frame:AddChild(TEMPLATES.StandardButton(function()
        self.Func.Close()
    end, "关闭", {2*btn_size, btn_size}))
    self.btn_highlight = self.frame:AddChild(TEMPLATES.StandardButton(function()
        self.print_text:SetString(self.Func.Highlight(GetData()))
    end, "高亮", {2*btn_size, btn_size}))
    self.btn_click = self.frame:AddChild(TEMPLATES.StandardButton(function()
        self.print_text:SetString(self.Func.Click(GetData()))
    end, "查找", {2*btn_size, btn_size}))

    self.btn_close:SetPosition(-posx, -posy)
    self.btn_highlight:SetPosition(0, -posy)
    self.btn_click:SetPosition(posx, -posy)
end)


function Sch:MakePrintText(font_size, width, height)
    local t = Text(DIALOGFONT, font_size)
    t:SetRegionSize(width, height)
    t:SetHAlign(ANCHOR_LEFT)
    t:SetVAlign(ANCHOR_TOP)
    t:EnableWordWrap(true)
    return t
end


function Sch:MakeFrame(width, height)
    local atlas = resolvefilepath(CRAFTING_ATLAS)
    local w = Widget("frame")
    local shift_line,shift_top,shift_bottom = 12, 10, 8
    

    local sides = w:AddChild(Widget("sides"))
    local left = sides:AddChild(Image(atlas, "side.tex"))
    local right = sides:AddChild(Image(atlas, "side.tex"))
    local top = sides:AddChild(Image(atlas, "top.tex"))
    local bottom = sides:AddChild(Image(atlas, "bottom.tex"))
    left:SetPosition(-width / 2 - shift_line, 1)
    right:SetPosition(width / 2 + shift_line, 1)
    top:SetPosition(0, height / 2 + shift_top)
    bottom:SetPosition(0, -height / 2 - shift_bottom)

    left:ScaleToSize(-26, -(height - 20))
    right:ScaleToSize(26, height - 20)
    top:ScaleToSize(width+33, 38)
    bottom:ScaleToSize(width+33, 38)

    
    w.fill = w:AddChild(Image(atlas, "backing.tex"))
	w.fill:ScaleToSize(width + shift_line, height+shift_top+shift_bottom)
	w.fill:SetTint(1, 1, 1, 0.2)
    return w
end

function Sch:MakeSearchBox(box_width, box_height)
    local w = Widget("search")
    w.textbox_root = w:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, box_width, box_height))
    local tb = w.textbox_root.textbox
    tb:SetSize(30)
    tb:SetTextLengthLimit(20)
    tb:SetForceEdit(true)
    tb:EnableScrollEditWindow(true)
    tb:SetTextPrompt("输入物品名或代码", UICOLOURS.GREY)
    tb.prompt:SetHAlign(ANCHOR_MIDDLE)

    return w
end

function Sch:MakeCheckBox(size, init_value)
    local w = Widget("check")
    w.checkbox_value = init_value
    local function OnClick()
        w.checkbox_value = not w.checkbox_value
        return w.checkbox_value
    end
    w.checkbox = w:AddChild(TEMPLATES.StandardCheckbox(OnClick, size, w.checkbox_value, nil, {text = "精确查找"}))
    return w
end


function Sch:SetUIPos(reset)
    if reset then
        self.Func.SavePos({x = self.init_x, y = self.init_y})
    end
    self:SetPosition(self.Data.posx or self.init_x, self.Data.posy or self.init_y)
end

return Sch