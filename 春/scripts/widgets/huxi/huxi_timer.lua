

local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local h_util = require "util/hudutil"

local Timer = Class(Widget, function(self, funcs)
    Widget._ctor(self, "huxiTimer")
    self.Func = funcs
    self.Btns = {}

    self.init_x, self.init_y = h_util:ToSize(120, 996)
end)

local xml_craft = resolvefilepath(CRAFTING_ATLAS)
function Timer:BuildTimer(setting, data)
    self.setting = setting or self.setting or {}
    self.data = data or self.data or {}
    if self.root then self.root:Kill() end
    self.Btns = {}
    self.root = self:AddChild(Widget("root"))
    
    local num_col = self.setting.num_col or 10
    local btn_size = h_util:ToRate(self.setting.btn_size or 50)

    local spacing_y = btn_size * (self.setting.space_y or 18) * 0.1
    local spacing_x = btn_size * (self.setting.space_x or 15) * 0.1
    local text_posy = btn_size * -(self.setting.font_posy or 10) * 0.1
    local text_size = btn_size * (self.setting.font_size or 10) * 0.06

    
    local fill = self.root:AddChild(Image(xml_craft, "backing.tex"))
    local data_count = #self.data
    local bg_width = data_count>num_col and num_col*spacing_x or data_count*spacing_x
    local bg_height = (math.floor((data_count-1)/num_col)+1)*spacing_y+text_size/2
    fill:SetPosition((bg_width-spacing_x)/2, -bg_height/2+spacing_y/4)
    fill:ScaleToSize(bg_width, bg_height)
    fill:SetTint(1, 1, 1, 0)
    self.fill = fill
    

    for i, btn_data in pairs(self.data)do
        local btn = self.root:AddChild(Widget("btn_text"))
        local x_pos = (i-1)%num_col * spacing_x
        local y_pos = math.floor((i-1)/num_col) * -spacing_y
        btn:SetPosition(x_pos, y_pos)
        btn.img = btn:AddChild(Image(btn_data.xml, btn_data.tex))
        h_util:ActivateBtnScale(btn.img, btn_size)
        h_util:BindMouseClick(btn.img, {
            [MOUSEBUTTON_LEFT] = btn_data.fn_left,
            [MOUSEBUTTON_RIGHT] = btn_data.fn_right,
        })

        btn.text = btn:AddChild(Text(NUMBERFONT, text_size, btn_data.text))
        if btn_data.color then
            btn.text:SetColour(btn_data.color)
        end
        btn.text:SetPosition(0, text_posy)

        btn:SetTooltip(btn_data.describe)
        btn:SetTooltipPos(0, text_posy*1.3 ,0)
        self.Btns[btn_data.id] = btn
    end

    if self.setting.penetrate then
        self.root:SetClickable(false)
    else
        fill:SetOnGainFocus(function()fill:SetTint(1, 1, 1, 0.4)end)
        fill:SetOnLoseFocus(function()fill:SetTint(1, 1, 1, 0)end)
        fill:SetHoverText(STRINGS.LMB.." 可以拖拽\n黏着鼠标请按Esc", {offset_y = -(bg_height+text_size)/2, colour = UICOLOURS.GOLD})
        h_util:ActivateUIDraggable(self, self.Func.SavePos, self.fill)
    end
    self:SetUIPos()
    
end

function Timer:HasUI(id)
    return self.Btns[id]
end

function Timer:ChanUI(id, meta)
    local w = self.Btns[id]
    if w then
        if meta.text then
            if meta.text.text then
                w.text:SetString(meta.text.text)
            end
            if meta.text.color then
                w.text:SetColour(meta.text.color)
            end
        end
        if meta.img then
            if meta.img.xml and meta.img.tex then
                w.img:SetTexture(meta.img.xml, meta.img.tex)
            end
        end
        if meta.describe then
            w:SetTooltip(meta.describe)
        end
    end
end


function Timer:SetUIPos(reset)
    if reset then
        if self.fill then
            self.Func.SavePos({x = self.init_x, y = self.init_y})
            self:BuildTimer()
        end
    else
        self:SetPosition(self.setting.posx or self.init_x, self.setting.posy or self.init_y)
    end
end


return Timer
