
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local xml_hx = "images/hx_ui.xml"
local Text = require "widgets/text"
local size_text = 50
local c_util = require "util/calcutil"

local info_ui = {
    top = {
        h = 80,
        tex = "menu_right_top.tex",
        tex_focus = "menu_right_top_focus.tex",
        offset_y = -10,
    },
    bot = {
        h = 85,
        tex = "menu_right_bot.tex",
        tex_focus = "menu_right_bot_focus.tex",
        offset_y = 10,
    },
    mid = {
        h = 68,
        tex = "menu_right_mid.tex",
        tex_focus = "menu_right_mid_focus.tex",
    }
}

local RMenu = Class(Widget, function(self, items, meta)
    Widget._ctor(self, "rightmenu")
    self.width_bg = 370
    self.menu_items = self:AddChild(self:BuildItems(items))
    self.height_bg = -self.menu_items.height_bg
    
    
    
    self.menu_items:SetPosition(self.width_bg/2, 0)
    self.meta = meta or {}
    
    
end)


function RMenu:BuildItems(items)
    local w = Widget("menu_right_bg")
    items = items or {}
    local pos_y = 0
    for i, item in ipairs(items) do 
        local cate = i == 1 and "top" or (i == #items and "bot" or "mid")
        
        local btn = w:AddChild(self:BuildItem(cate, item))
        local h = info_ui[cate].h
        pos_y = pos_y - (h/2-1) 
        btn:SetPosition(0, pos_y)
        pos_y = pos_y - (h/2-1)
    end
    w.height_bg = pos_y
    return w
end


function RMenu:BuildItem(cate, item)
    local w = Widget("menu_right_item")
    local info = info_ui[cate]
    w.imgbtn = w:AddChild(ImageButton(xml_hx, info.tex,info.tex_focus))
    w.imgbtn.scale_on_focus = false
    w.imgbtn.clickoffset = Vector3(0, 0, 0)
    w.imgbtn:SetOnClick(function()
        if type(item.cb)=="function" then
            item.cb()
        end
        self:Kill()
        return true
    end)
    
    w.text = w.imgbtn:AddChild(Text(CHATFONT, size_text, c_util:TruncateChineseString(item.text or "", 10), UICOLOURS.BLACK))
    local rw = w.text:GetRegionSize()
    w.text:SetPosition(rw/2-self.width_bg*.4, info.offset_y or 0)
    return w
end

function RMenu:SetGPos(x, y, x_ori, y_ori)
    
    if not x then
        x, y = TheSim:GetPosition()
    end
    local sw, sh = TheSim:GetScreenSize()
    
    local rate = .05
    local _x, _y = x+1, y
    if (y_ori or y) - self.height_bg < rate * sh then
        if (y_ori or y) + self.height_bg > (1-rate) * sh then
            _y = .5*sh+.5*self.height_bg
        else
            _y = y+self.height_bg
        end
    end
    self:SetScale(.6)
    if self.parent then
        local pos_p_w = self.parent:GetWorldPosition() 
        local pos_p_abs = pos_p_w + Vector3(sw/2, sh/2, 0)
        local pos_c_rel = Vector3(_x, _y, 0) - pos_p_abs
        local scale = self.parent:GetScale().x
        self:SetPosition(pos_c_rel/scale)
    end
    
    
end





return RMenu