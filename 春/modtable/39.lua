local pr = require "screens/plantregistrypopupscreen"
local function fn()
    TheFrontEnd:PushScreen(pr(ThePlayer))
end
m_util:AddBindConf("sw_planthant", fn, nil,
    {"耕种图鉴", "plantregistryhat", "点击打开种地图鉴", true, fn, nil, 7998})
