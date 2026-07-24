local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local AccountItemFrame = require "widgets/redux/accountitemframe"

local BeefaloSkinPresetsPopup = Class(Screen, function(self, data, meta, apply_cb)
    Screen._ctor(self, "BeefaloSkinPresetsPopup")

    self.apply_cb = apply_cb

    self.list_names = t_util:IPairToIPair(data, function(suitdata)
        return suitdata.name or {}
    end)

    self.list_items = t_util:IPairToIPair(data, function(suitdata)
        return suitdata.suit or {}
    end)

    local scroll_height = 460
    local content_width = 390
    local item_height = 60

    self.black = self:AddChild(TEMPLATES.BackgroundTint())
    self.proot = self:AddChild(TEMPLATES.ScreenRoot())

    self.buttons = {
        {
            text=STRINGS.UI.HELP.BACK,
            cb = function()
                self:_Cancel()
            end,
            controller_control = CONTROL_CANCEL,
        },
    }
    self.dialog = self.proot:AddChild(TEMPLATES.CurlyWindow(470,
            scroll_height,
            meta.title or "来自套装",
            self.buttons,
            30,
            "" 
        ))

    self.oncontrol_fn, self.gethelptext_fn = TEMPLATES.ControllerFunctionsFromButtons(self.buttons)
    if TheInput:ControllerAttached() then
        self.dialog.actions:Hide()
    end


    local function ScrollWidgetsCtor(context, i)
        local item = Widget("item-"..i)
        item.root = item:AddChild(Widget("root"))

        item.row_label = item.root:AddChild(Text(BODYTEXTFONT, 28))
        item.row_label:SetColour(UICOLOURS.IVORY)
        item.row_label:SetHAlign(ANCHOR_RIGHT)

        local x_start = -170
        local x_step = 50

        item.row_label:SetPosition(-210, -1)
        item.root:SetPosition(20, 0)

        item.beef_head_icon = item.root:AddChild( AccountItemFrame() )
        item.beef_head_icon:SetStyle_Normal()
        item.beef_head_icon:SetScale(0.4)
        item.beef_head_icon:SetPosition(x_start + 0 * x_step,0)

        item.beef_horn_icon = item.root:AddChild( AccountItemFrame() )
        item.beef_horn_icon:SetStyle_Normal()
        item.beef_horn_icon:SetScale(0.4)
        item.beef_horn_icon:SetPosition(x_start + 1 * x_step,0)

        item.beef_body_icon = item.root:AddChild( AccountItemFrame() )
        item.beef_body_icon:SetStyle_Normal()
        item.beef_body_icon:SetScale(0.4)
        item.beef_body_icon:SetPosition(x_start + 2 * x_step,0)

        item.beef_feet_icon = item.root:AddChild( AccountItemFrame() )
        item.beef_feet_icon:SetStyle_Normal()
        item.beef_feet_icon:SetScale(0.4)
        item.beef_feet_icon:SetPosition(x_start + 3 * x_step,0)

        item.beef_tail_icon = item.root:AddChild( AccountItemFrame() )
        item.beef_tail_icon:SetStyle_Normal()
        item.beef_tail_icon:SetScale(0.4)
        item.beef_tail_icon:SetPosition(x_start + 4 * x_step,0)

        item.load_btn = item.root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "apply_skins.tex", nil, nil, nil, function(a) self:_LoadPreset(item.i) end, STRINGS.UI.SKIN_PRESETS.LOAD))
        item.load_btn:SetPosition(80,-1)
        item.load_btn:SetScale(0.7)

        item.text_label = item.root:AddChild(Text(BODYTEXTFONT, 28))
        item.text_label:SetColour(UICOLOURS.IVORY)
        item.text_label:SetHAlign(ANCHOR_LEFT)
        item.text_label:SetPosition(150, 0)
        item.text_label:SetString("")

        item.focus_forward = item.load_btn

        item:SetOnGainFocus(function()
            self.scroll_list:OnWidgetFocus(item)
        end)

        return item
    end
    local function ScrollWidgetApply(context, item, data, index)
        if data then
            item.i = index
            item.row_label:SetString(tostring(index)..":")
            item.text_label:SetString(self.list_names[index])

            if data.beef_body then
                item.beef_body_icon:SetItem(data.beef_body)
            else
                item.beef_body_icon:SetItem("beef_body_default1")
            end

            if data.beef_horn then
                item.beef_horn_icon:SetItem(data.beef_horn)
            else
                item.beef_horn_icon:SetItem("beef_horn_default1")
            end

            if data.beef_head then
                item.beef_head_icon:SetItem(data.beef_head)
            else
                item.beef_head_icon:SetItem("beef_head_default1")
            end

            if data.beef_feet then
                item.beef_feet_icon:SetItem(data.beef_feet)
            else
                item.beef_feet_icon:SetItem("beef_feet_default1")
            end

            if data.beef_tail then
                item.beef_tail_icon:SetItem(data.beef_tail)
            else
                item.beef_tail_icon:SetItem("beef_tail_default1")
            end

            item.root:Show()
        else
            item.root:Hide()
        end
    end

    self.scroll_list = self.proot:AddChild(
        TEMPLATES.ScrollingGrid(
            self.list_items,
            {
                context = {},
                widget_width  = content_width + 40,
                widget_height =  item_height,
                num_visible_rows = math.floor(scroll_height/item_height) - 1,
                num_columns      = 1,
                item_ctor_fn = ScrollWidgetsCtor,
                apply_fn     = ScrollWidgetApply,
                scrollbar_height_offset = -60,
                scrollbar_offset = -content_width - item_height,
            }
        ))
    self.scroll_list:SetPosition(0, 30)

    self.default_focus = self.scroll_list
end)

function BeefaloSkinPresetsPopup:_LoadPreset(i)
    self.apply_cb(self.list_items[i])
    TheFrontEnd:PopScreen(self)
end

function BeefaloSkinPresetsPopup:OnControl(control, down)
    if BeefaloSkinPresetsPopup._base.OnControl(self,control, down) then
        return true
    end

    return self.oncontrol_fn(control, down)
end

function BeefaloSkinPresetsPopup:GetHelpText()
    return self.gethelptext_fn()
end

function BeefaloSkinPresetsPopup:_Cancel()
    TheFrontEnd:PopScreen(self)
end

return BeefaloSkinPresetsPopup
