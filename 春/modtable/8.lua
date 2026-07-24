local cp = require "screens/cookbookpopupscreen"
local function fn()
    TheFrontEnd:PushScreen(cp(ThePlayer))
end
m_util:AddBindConf("sw_cookbook", fn, nil, {"烹饪指南", "cookbook", "菜谱", true, fn, nil, 7999})

if not m_util:IsMilker() then
    return
end
local Sb = require "screens/redux/scrapbookscreen"
local _PopulateInfoPanel = Sb.PopulateInfoPanel
Sb.PopulateInfoPanel = function(...)
    if ThePlayer then
        return _PopulateInfoPanel(...)
    else
        _G.ThePlayer = {
            userid = ""
        }
        local ret = _PopulateInfoPanel(...)
        _G.ThePlayer = nil
        return ret
    end
end

local _OnBecomeActive = Sb.OnBecomeActive
Sb.OnBecomeActive = function(...)
    if ThePlayer then
        return _OnBecomeActive(...)
    else
        _G.ThePlayer = {
            PushEvent = function()
            end
        }
        local ret = _OnBecomeActive(...)
        _G.ThePlayer = nil
        return ret
    end
end

m_util:AddBindIcon("图鉴", {
    xml = HUD_ATLAS,
    tex = "tab_book.tex"
}, "查看游戏图鉴", true, function()
    TheFrontEnd:PushScreen(Sb())
end, false, 7998)
