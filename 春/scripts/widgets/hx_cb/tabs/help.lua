local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local TEMPLATES = require "widgets/redux/templates"


local HP = Class(Widget, function(self, CB)
    Widget._ctor(self, "huxi_console_board_console")

    local data_str = {"width_bg", "height_bg", "size_font"}
    t_util:IPairs(data_str, function(str) self[str] = CB[str] end)


    self.girl = self:AddChild(Image("images/cb_under_construction.xml", "cb_under_construction.tex"))
    self.girl:SetSize(512, 320)
    self.girl:SetPosition(0, 88)

    self.tip = self:AddChild(Text(CODEFONT, 35, "帮助页面施工中...\nQQ群：2155066095\n有bug或疑问可以先加群哦(*^_^*)"))
    self.tip:SetPosition(-100, -150)

    self.bili1 = self:AddChild(TEMPLATES.StandardButton(function()
        VisitURL("https://www.bilibili.com/video/BV1fm2fB7EpK/", true)
    end, "教程演示", {150, 60}))
    self.bili1:SetPosition(233, -150)
end)


return HP