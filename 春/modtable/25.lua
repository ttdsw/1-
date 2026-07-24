AddClassPostConstruct("screens/redux/playersummaryscreen", function(self)
    local TEMPLATES = require "widgets/redux/templates"
    self.bottom_root:AddChild(TEMPLATES.StandardButton(function()
        if m_util:IsOffline() then
            return h_util:CreatePopupWithClose("提示", "离线模式下，该功能不可用。")
        end
        local screen = require("screens/huxi/skinqueue_plus")
        if screen then
            TheFrontEnd:PushScreen(screen())
        end
    end, "重复皮肤信息(新!)", {225, 40})):SetPosition(300, 10)
end)
