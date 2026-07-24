local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local Text = require "widgets/text"
local c_util, e_util, h_util, m_util, t_util  = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil"
local tint = 0.7
local atlas_skill = "images/skilltree.xml"

local MCover = Class(Widget, function(self, parent, funcs, save_data, meta_data)
    Widget._ctor(self, "MainCover")
    self.parent = parent
    self.funcs = funcs
    self.id = save_data.id
    self.meta_data = meta_data
    self.save_data = save_data
    
    self:UIBuild()
    self:ChanArrow()
end)

function MCover:UIBuild()
    self.root = self:AddChild(Widget("root"))
    self.root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
    local atlas_craft = CRAFTING_ATLAS
    local atlas_global = "images/global_redux.xml"
    local atlas_avatar = "images/avatars.xml"
    
    self.fill = self.root:AddChild(Image(atlas_craft, "backing.tex"))
    self.fill:SetTint(1, 1, 1, tint)
    local width, height = RESOLUTION_X, RESOLUTION_Y/5
    self.fill:ScaleToSize(width, height)
    local fill_x, fill_y = width/2, RESOLUTION_Y-height/2
    self.fill:SetPosition(fill_x, fill_y)
    
    local size_arr = height/4
    local btn_y = fill_y+size_arr
    self.btns = self.root:AddChild(Widget("btns"))
    self.btns:SetPosition(fill_x, btn_y)
    
    self.arr_l = self.btns:AddChild(ImageButton(atlas_global, "arrow2_left.tex", "arrow2_left_over.tex", "arrow_left_disabled.tex", "arrow2_left_down.tex", nil,{1,1}, {0,0}) )
    self.arr_r = self.btns:AddChild(ImageButton(atlas_global, "arrow2_right.tex", "arrow2_right_over.tex", "arrow_right_disabled.tex", "arrow2_right_down.tex", nil,{1,1}, {0,0}))
    self.arr_l:SetPosition(-2*size_arr, 0)
    self.arr_r:SetPosition(2*size_arr, 0)
    h_util:ActivateBtnScale(self.arr_l, size_arr)
    h_util:ActivateBtnScale(self.arr_r, size_arr)
    self.arr_l:SetOnClick(function()
        self.id = self.id - 1
        self:ChanArrow()
        self.funcs.SetFrontend(self.parent, self.id)
    end)
    self.arr_r:SetOnClick(function()
        self.id = self.id + 1
        self:ChanArrow()
        self.funcs.SetFrontend(self.parent, self.id)
    end)
    
    
    local size_btn = size_arr * 0.8
    self.btn_reset = self.btns:AddChild(Image(atlas_avatar, "loading_indicator.tex"))
    h_util:ActivateBtnScale(self.btn_reset, size_btn)
    h_util:BindMouseClick(self.btn_reset, {
        [MOUSEBUTTON_LEFT] = function()
            self.id = self.save_data.id
            self:ChanArrow()
            self.funcs.SetFrontend(self.parent, self.id)
        end,
    })
    
    
    self.btn_lock = self.btns:AddChild(Image(atlas_skill, "unlocked_over.tex"))
    self.btn_lock:SetPosition(4*size_arr, 0)
    h_util:ActivateBtnScale(self.btn_lock, size_btn)
    h_util:BindMouseClick(self.btn_lock, {
        [MOUSEBUTTON_LEFT] = function()
            if self.save_data.id == self.id then
                self.save_data.id = 0
            else
                self.save_data.id = self.id
            end
            self.funcs.Save()
            self:RefreshLock()
        end,
    })
    
    
    self.btn_eye = self.btns:AddChild(Image(atlas_skill, "skill_icon_bw.tex"))
    self.btn_eye:SetPosition(5.2*size_arr, 0)
    h_util:ActivateBtnScale(self.btn_eye, size_arr)
    local value_hide
    h_util:BindMouseClick(self.btn_eye, {
        [MOUSEBUTTON_LEFT] = function()
            value_hide = not value_hide
            self.funcs.VisableUI(self.parent, value_hide)
            self.btn_eye:SetTexture(atlas_skill, value_hide and "skill_icon_textbox_white.tex" or "skill_icon_bw.tex")
        end,
    })
    
    self.info = self.btns:AddChild(Text(TITLEFONT, 30))
    self.info:SetPosition(0, -2*size_arr)
    

    self:RefreshLock()
    self:HideUI()
end

function MCover:RefreshLock()
    if self.save_data.id == self.id then
        self.btn_lock:SetTexture(atlas_skill, "locked_over.tex")
    else
        self.btn_lock:SetTexture(atlas_skill, "unlocked_over.tex")
    end
end


function MCover:ChanArrow()
    self.arr_l:Enable()
    self.arr_r:Enable()
    if self.id < 0 then
        self.id = self.meta_data.len
    elseif self.id > self.meta_data.len then
        self.id = 0
    end
    self.info:SetString(self.funcs.SetDesc(self.id))
    self:RefreshLock()
end


function MCover:OnGainFocus()
    MCover._base.OnGainFocus(self)
    if m_util:IsHuxi() and TheInput:IsKeyDown(KEY_SHIFT) then
        self:Hide()
    else
        self.btns:Show()
        self.fill:SetTint(1, 1, 1, tint)
    end
end

function MCover:HideUI()
    self.btns:Hide()
    self.fill:SetTint(1, 1, 1, 0)
end

function MCover:OnLoseFocus()
    MCover._base.OnLoseFocus(self)
    self:HideUI()
end



return MCover