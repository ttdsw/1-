


local HWindow = require "widgets/huxi/huxi_window"
local HIcon = require "widgets/huxi/huxi_icon"

local function BuildIcon(self)
    if self.mboard then
        self.mboard:Kill()
    end
    self.mboard = self:AddChild(HWindow())
    if self.hicon then
        self.hicon:Kill()
    end
    self.hicon = self:AddChild(HIcon())
end

AddClassPostConstruct("widgets/controls", BuildIcon)

if m_util:IsHuxi() then
    AddClassPostConstruct("screens/redux/multiplayermainscreen", BuildIcon)
end

m_util:AddBindConf("sw_mainboard", h_util.CtrlBoard)
local function getIcon()
    return h_util:GetControls().hicon or h_util:GetActiveScreen().hicon
end
local function func_r()
    local icon = getIcon()
    if icon then
        icon:GetResetFn()()
    end
end
local function func_l()
    local icon = getIcon()
    if icon then
        icon:GetSettingFn()()
    end
end
local xml, tex = h_util:GetRandomSkin(true)
m_util:AddBindIcon("面板与按钮", {
    xml = xml,
    tex = tex
}, STRINGS.LMB .. '高级设置' .. STRINGS.RMB .. '重置小图标', true, func_l, func_r, 99999)
m_util:AddBindIcon("功能绑定", "butterflymuffin", "修改模组功能的绑定设置", true, function()
    m_util:AddBindShowScreen({
        title = "功能绑定",
        id = "funcsbind",
        data = t_util:MergeList({{
            id = "bilibili",
            prefab = "bilibili",
            type = "imgstr",
            label = "视频教程",
            hover = "点击查看视频教程",
            fn = function()
                VisitURL("https://www.bilibili.com/video/BV1BVCQBmEVd", true)
            end
        }}, m_util:LoadReBindData())
    })()
end, nil, 99998)
