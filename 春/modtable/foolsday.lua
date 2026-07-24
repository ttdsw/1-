local code_joke = "EKAF-EERF-AHAH-1YAD-1RPA"
local code_jokes = {
    code_joke,
    "9BKR-T7L4-FQJ3-8W5S-2N9P",
    "YL7H-MV3E-SXK8-4T9R-1D6Z",
    "4F8S-QW2P-K9JH-3R7G-VX4T",
    "A7H2-9T3L-P6SX-8R4W-M5QK",
    "3J7X-8H4V-2K9S-L6FQ-D5TZ",
}
local jokes = {}
local function addjoke(text, color, img)
    table.insert(jokes, {text=text, color=color, img=img})
end
addjoke("由于您启用了作弊类模组，已被管理员封禁！", "深红色", "view_ban")
addjoke("按住「ALT+F4」加速进入游戏。", "春绿色")
addjoke("感谢游玩, 赠送您一份皮肤兑换码「"..code_joke.."」请在「物品收藏」页面激活。", "黄色", "quagmire_key")
addjoke("倒计时三分钟...永恒领域即将降临全球.....", "呼吸蓝", "world")
addjoke("硬盘空间不足！正在卸载饥荒...")

local _, joke
if math.random() < 0.2 then
    _, joke = t_util:GetRandomItem(jokes)
end

local Loadingwidget = require "widgets/redux/loadingwidget"
local _SetEnabled = Loadingwidget.SetEnabled
Loadingwidget.SetEnabled = function(self, ...)
    local ret = _SetEnabled(self, ...)
    if joke then
        if self.loading_tip_text and joke.text then
            self.loading_tip_text:SetString(joke.text)
        end
        if self.loading_tip_icon and joke.img then
            local xml, tex = h_util:GetPrefabAsset(joke.img)
            if xml then
                self.loading_tip_icon:SetTexture(xml, tex)
            end
        end
    end
    return ret
end

local _KeepAlive = Loadingwidget.KeepAlive
Loadingwidget.KeepAlive = function(self, ...)
    local ret = _KeepAlive(self, ...)
    if joke and joke.color and self.loading_tip_text then
        self.loading_tip_text:SetColour(h_util:GetRGB(joke.color))
    end
    return ret
end

local items = t_util:GetMetaIndex(TheItems)
if not items then return end
local _RedeemCode = items.RedeemCode
items.RedeemCode = function(self, code, ...)
    if table.contains(code_jokes, code) then
        local TKU = require("screens/thankyoupopup")
        local pop = TKU({{item="emote_laugh", item_id=0, gifttype="LUNAR_NY", message="愚人节快乐！"}})
        local _SetSkinName = pop.SetSkinName
        pop.SetSkinName = function(self, ...)
            _SetSkinName(self, ...)
            self.upper_banner_text:SetString("哈哈")
            self.item_name:SetString("你啥也没收到")
        end
        TheFrontEnd:PushScreen(pop)
    else
        return items.RedeemCode(self, code,...)
    end
end
