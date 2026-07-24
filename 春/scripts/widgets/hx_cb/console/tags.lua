
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local m_util = require "util/modutil"
local f_util = require "util/fn_hxcb"
local hxcb_tags = require "data/hx_cb/tags"
local TagBox = require "widgets/hx_cb/console/tagbox"
local c_util, e_util, h_util, t_util = require "util/calcutil", require "util/entutil",
    require "util/hudutil", require "util/tableutil"

local save_data = f_util.save_data
local ID_TAG_DEFAULT = "creature"    


local TS = Class(Widget, function(self, CS, CB)
    Widget._ctor(self, "huxi_console_board_tags")

    
    local data_str = {"width_bg", "height_bg", "size_font", 
    "col_grid", "size_cell", "spacing_cell", "width_cell", "width_grid", "grid_x",
    "size_cate", "spacing_cate", "width_cate", "col_cate", "shift_cate", "posy_2"}
    t_util:IPairs(data_str, function(str) self[str] = CS[str] end)


    self.CB = CB
    self.coloff_focus, self.coloff_normal = .85, .65
    self.width_tag, self.height_tag = 140, self.height_bg / #hxcb_tags
    



    self.dir_ru = self:AddChild(Widget("tags"))
    local posx_ru, posy_ru = (self.width_bg + self.width_tag) / 2 + 19, self.height_bg * .5 + self.height_tag * -.5
    posx_ru = save_data.lright and -446 or posx_ru
    self.dir_ru:SetPosition(posx_ru, posy_ru)
    CB.tags = {}
    local colors = c_util:SplitHueRing(#hxcb_tags - 3)
    table.insert(colors, h_util:GetRGB("漆白"))
    table.insert(colors, h_util:GetRGB("半白"))
    table.insert(colors, h_util:GetRGB("灰色"))

    for i, data_tag in ipairs(hxcb_tags) do
        data_tag.color = colors[i]
        if #hxcb_tags - 2 == i then
            data_tag.color_font = {0, 0, 0, 1}
        end
        local tag = self.dir_ru:AddChild(self:BuildTag(data_tag))
        CB.tags[data_tag.id] = tag
        tag:SetPosition(0, (i - 1) * -self.height_tag)
    end

    
    self.tag_selected = save_data.id_tag and CB.tags[save_data.id_tag] or CB.tags[ID_TAG_DEFAULT]
    if h_util:IsValid(self.tag_selected) then
        self.tag_selected:Select()
    end
end)


function TS:BuildTag(data)
    local xml = save_data.lright and "images/hx_ui.xml" or "images/scrapbook.xml"
    local tag = ImageButton(xml, "tab.tex")
    local buttonwidth = save_data.lright and -70 or self.width_tag
    local buttonheight = self.height_tag
    tag:ForceImageSize(buttonwidth, buttonheight)
    tag.scale_on_focus = false
    local r, g, b = unpack(data.color)
    local c1, c2 = self.coloff_focus, self.coloff_normal
    tag:SetImageFocusColour(r * c1, g * c1, b * c1, 1)
    tag:SetImageNormalColour(r * c2, g * c2, b * c2, 1)
    tag:SetImageSelectedColour(r * c1, g * c1, b * c1, 1)
    
    
    local _OnMouseButton = tag.OnMouseButton
    tag.OnMouseButton = function(ui, btn, down, ...)
        if btn == MOUSEBUTTON_LEFT and down then
            self.tag_selected:Unselect()
            self.tag_selected = tag
            tag:Select()
        end
        return _OnMouseButton(ui, btn, down, ...)
    end
    
    
    
    
    
    

    tag:SetOnSelect(function()
        tag.selectimg:Show()
        local tid = data.id
        if not tid then return end
        f_util.fn_save("id_tag")(tid)
        if h_util:IsValid(self.tag_box) then
            self.tag_box:Kill()
        end
        local status, info = pcall(require, "data/hx_cb/cates/"..tid)
        if status then
            self.tag_box = self:AddChild(TagBox(self, tid, info, self.CB))
        else
            m_util:print(tid, info)
        end
    end)

    tag:SetOnUnSelect(function()
        tag.selectimg:Hide()
    end)

    tag.focusimg = tag:AddChild(Image(xml, "tab_over.tex"))
    tag.focusimg:ScaleToSize(buttonwidth, buttonheight)
    tag.focusimg:Hide()

    tag.selectimg = tag:AddChild(Image(xml, "tab_over.tex"))
    local size_shift = save_data.lright and 0 or 4
    tag.selectimg:ScaleToSize(buttonwidth + size_shift, buttonheight + size_shift)
    tag.selectimg:SetTint(1, 1, 0, 1)
    tag.selectimg:Hide()

    tag:SetOnGainFocus(function()
        tag.focusimg:Show()
    end)
    tag:SetOnLoseFocus(function()
        tag.focusimg:Hide()
    end)

    tag:AddChild(Text(HEADERFONT, self.size_font, data.name or data.id, data.color_font or UICOLOURS.WHITE))
        :SetPosition(save_data.lright and 7 or 10, -8)
    return tag
end


return TS