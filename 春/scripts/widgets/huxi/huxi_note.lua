
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local c_util, e_util, h_util, m_util, t_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil"
local xml_scrap = "images/scrapbook.xml"

local NOTE = Class(Widget, function(self, funcs, save_data, note_data, id)
    Widget._ctor(self, "Huxi_Note")
    self.Func = funcs
    self.Data = save_data
    self.Note = note_data
    self.init_x, self.init_y = h_util.screen_w/3, h_util.screen_h/2
    self.font_size = 40

    self:BuildUI(id)
end)

function NOTE:BuildUI(id)
    local data = self.Note[id]
    self.width, self.height = data.width, data.height

    self:SetUIPos()
    if self.root then
        self.root:Kill()
    end
    self.root = self:AddChild(Widget("root"))

    
    local bg_width, bg_height = self.width+2*self.font_size, self.height+2*self.font_size
    self.bg = self.root:AddChild(h_util:SpawnScrapBookImage(bg_width, bg_height))
    self.bg:SetHoverText(STRINGS.LMB.."可拖拽 \n黏着鼠标请按Esc", {offset_y = -self.height/2-3*self.font_size, colour = UICOLOURS.GOLD})
    
    self.title_text = self.root:AddChild(self:MakeTitle(data.title))
    self.print_text = self.root:AddChild(self:MakePrintText(data.content))
    
    self.btn_close = self.root:AddChild(self:MakeCloseBtn())
    
    self.flip = self.root:AddChild(self:MakeFlip(id))

    h_util:ActivateUIDraggable(self, self.Func.SavePos, self.bg)
end

function NOTE:MakeFlip(id)
    local flip = Widget("radio")
    flip.arr_l = flip:AddChild(ImageButton("images/global_redux.xml", "arrow2_left.tex", "arrow2_left_over.tex", "arrow_left_disabled.tex", "arrow2_left_down.tex", nil,{1,1}, {0,0}) )
    flip.arr_r = flip:AddChild(ImageButton("images/global_redux.xml", "arrow2_right.tex", "arrow2_right_over.tex", "arrow_right_disabled.tex", "arrow2_right_down.tex", nil,{1,1}, {0,0}) )
    local shift = self.width/2+self.font_size
    flip.arr_l:SetPosition(-shift, 0)
    flip.arr_r:SetPosition(shift, 0)

    local count = #self.Note
    if id == 1 then
        flip.arr_l:Hide()
    end
    if id == count then
        flip.arr_r:Hide()
    end

    local num_t = t_util:BuildNumInsert(1, count, 1, function()
        return true
    end)
    
    flip.arr_l:SetOnClick(function()
        self:BuildUI(t_util:GetNextLoopKey(num_t, id, true))
    end)
    flip.arr_r:SetOnClick(function()
        self:BuildUI(t_util:GetNextLoopKey(num_t, id))
    end)

    local size = self.font_size * 2
    h_util:ActivateBtnScale(flip.arr_l, size)
    h_util:ActivateBtnScale(flip.arr_r, size)
    
    self.root:SetOnGainFocus(function()
        flip:Show()
    end)
    self.root:SetOnLoseFocus(function()
        flip:Hide()
    end)
    flip:Hide()
    return flip
end


function NOTE:MakeCloseBtn()
    local btn = ImageButton("images/hx_or.xml", "wrong.tex")
    local size = self.font_size*0.3
    btn:SetPosition(self.width/2-size, self.height/2-size)
    btn:SetHoverText("关闭")
    btn:SetOnClick(function()
        self:Kill()
    end)
    h_util:ActivateBtnScale(btn, size*2)
    return btn
end


function NOTE:MakeTitle(text)
    local t = Text(HEADERFONT, self.font_size*1.2, text, h_util:GetRGB("黑色"))
    t:SetPosition(0, self.height/2)
    return t
end

function NOTE:MakePrintText(text)
    local t = Text(CHATFONT, self.font_size, text, h_util:GetRGB("黑色"))
    t:SetRegionSize(self.width, self.height)
    t:SetHAlign(ANCHOR_LEFT)
    t:EnableWordWrap(true)
    t:SetPosition(0, -self.font_size)
    return t
end


function NOTE:SetUIPos(reset)
    if reset then
        self.Func.SavePos({x = self.init_x, y = self.init_y})
    end
    self:SetPosition(self.Data.posx or self.init_x, self.Data.posy or self.init_y)
end



return NOTE




