
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
AddClassPostConstruct("screens/redux/purchasepackscreen", function(self)
    if not (self.filter_container and self.side_panel and self.purchase_root) then
        return
    end
    
    self.speech_bubble = self.side_panel:AddChild(UIAnim())
    self.speech_bubble:GetAnimState():SetBank("textbox")
    self.speech_bubble:GetAnimState():SetBuild("textbox")
    self.speech_bubble:SetScale(-.6, 1.1, .6)
    self.speech_bubble:GetAnimState():PlayAnimation("open", false)
    self.speech_bubble:Show()
    self.filter_container:SetPosition(0, -150, 0)
    self.speech_bubble:SetPosition(-11, 155, 0)
    
    self.text = self.side_panel:AddChild(Text(BUTTONFONT, 35, "", WHITE))
    
    self.text:SetVAlign(ANCHOR_MIDDLE)
    self.text:EnableWordWrap(true)
    self.text:SetPosition(-11, 155, 0)
    self.text:SetString("")

    if self.sales_btn then
        self.sales_btn:SetPosition(0, -80)
    end
end)

local function ParsePriceStr(price_str)
    local num, currency
    num, currency = string.match(price_str, "^([A-Z]+)%s*([%d%.]+)")
    if num and currency then
        return tonumber(currency), num
    end
    num, currency = string.match(price_str, "^(%d+)%s*([A-Za-z]+)")
    if num and currency then
        return tonumber(num), currency
    end
    num, currency = string.match(price_str, "^(%d+%.%d+)%s*([A-Za-z]+)")
    if num and currency then
        return tonumber(num), currency
    end
    num, currency = string.match(price_str, "^(%d+)%s*(%S+)$")
    if num and currency then
        return tonumber(num), currency
    end
end

local InfoAll = {}
local function Getinfo(iap)
    local itp = iap and iap.item_type
    if not itp then
        return
    end
    if InfoAll[itp] then
        return InfoAll[itp]
    end
    local title = GetSkinName(itp)
    local sale_active = IsSaleActive(iap)
    local pricestr = BuildPriceStr(iap, iap, sale_active)
    if not pricestr then
        return
    end
    local money, currency = ParsePriceStr(pricestr)
    if not money or money == 0 then
        return
    end
    local items = t_util:GetRecur(MISC_ITEMS, itp .. ".output_items")
    if not items then
        return
    end
    local sell_all, sell_own, buy_own = 0, 0, 0
    t_util:IPairs(items, function(item_key)
        local sell = TheItems:GetBarterSellPrice(item_key) or 0
        local buy = TheItems:GetBarterBuyPrice(item_key) or 0
        sell_all = sell_all + sell
        if TheInventory:CheckOwnership(item_key) then
            sell_own = sell_own + sell
        else
            buy_own = buy_own + buy
        end
    end)

    InfoAll[itp] = {
        iap = iap, 
        itp = itp, 
        money = money, 
        currency = currency, 
        sale_active = sale_active, 
        title = title, 
        items = items, 
        sell_all = sell_all, 
        sell_own = sell_own, 
        buy_own = buy_own, 
        value = math.floor(sell_all / money)
    }
    return InfoAll[itp]
end

local function OnFocus(w)
    local info = Getinfo(w and w.iap_def)
    if not info then
        return
    end
    local str = info.title .. "\n\n" .. "价格：" .. info.money .. info.currency .. "\n"
    if info.sell_own ~= 0 then
        str = str .. "购买后拆解：" .. info.sell_own .. " 线轴" .. "\n"
    end
    if info.buy_own ~= 0 then
        str = str .. "补齐缺少需：" .. info.buy_own .. " 线轴" .. "\n"
    end
    if info.sell_all ~= 0 then
        str = str .. "性价比：" .. info.value .. " 线轴/" .. info.currency .. "\n"
    end

    local bubble = t_util:GetRecur(h_util:GetActiveScreen("PurchasePackScreen"), "text")
    if bubble then
        bubble:SetString(str)
    end
end

local info_best
local function fn_tip(w)
    local info = Getinfo(w and w.iap_def)
    if not (info and info_best) then
        return
    end
    local str = ""
    if info.buy_own == 0 then
        str = "你已拥有该包的所有物品或皮肤！\n"
        if info.itp == info_best.itp then
            str = str .. "这个就是拆解线轴最划算的礼包！\n"
            str = str .. info.money .. info.currency .. " 可拆解出 " .. info.sell_own .. " 线轴。\n"
            str = str .. "性价比：" .. info_best.value .. " 线轴/" .. info_best.currency .. "。\n\n"
        else
            str = str .. "这个包 " .. info.money .. info.currency .. " 可拆解 " .. info.sell_own .. " 线轴，\n"
            str = str .. "性价比：" .. info.value .. " 线轴/" .. info.currency .. "。\n"
            str = str .. "如果你想拆线轴，更推荐【" .. info_best.title .. "】,\n"
            str = str .. "性价比：" .. info_best.value .. " 线轴/" .. info_best.currency .. "。\n\n"
        end
    else
        str = "当前价格：" .. info.money .. info.currency .. "，补齐物品或皮肤需要 " .. info.buy_own ..
                  " 线轴，\n"
        str = str .. "买此包然后拆掉多余皮肤，可获得 " .. info.sell_own .. " 线轴，\n"
        local bount = info.buy_own + info.sell_own
        str = str .. "加起来，就是花 " .. info.money .. info.currency .. " 买了 " .. bount .. " 线轴。\n"
        if info.itp == info_best.itp then
            str = str .. "此包就是是目前商城内，拆线轴性价比最高的礼包,"
            str = str .. "完整拆解相当于 " .. info.money .. info.currency .. " 换购 " .. info.sell_all ..
                      " 线轴,\n"
            str = str .. "它的性价比：" .. info.value .. " 线轴/" .. info.currency .. "。\n\n"
        else
            str = str .. "拆线轴目前【" .. info_best.title .. "】性价比最高：" .. info_best.value ..
                      " 线轴/" .. info_best.currency .. "，\n"
            local bount_best = info.money * info_best.value
            str = str .. "用" .. info.money .. info.currency .. "换算性价比包就是 " .. bount_best ..
                      " 线轴。\n\n"
            local str_add, money_best
            if bount > bount_best then
                str_add = "直接买【" .. info.title .. "】"
                money_best = bount - bount_best
            else
                str_add = "买【" .. info_best.title .. "】然后拆线轴再编织"
                money_best = bount_best - bount
            end
            money_best = tonumber(string.format("%.2f", money_best / info_best.value))
            str = str .. "所以，" .. str_add .. "更划算, 节省花费 " .. money_best .. info_best.currency ..
                      "。\n"
        end
    end

    if not IsSaleActive(info_best.iap) then
        str = str ..
                  "不过，当下科雷并未开展促销活动，推荐还是等等大促销，能节省更多󰀚！"
    end
    h_util:CreatePopupWithClose(info.title .. " · 购买建议", str, nil, {
        longness = "big"
    })
end

local str_pcscreen = "screens/redux/purchasepackscreen"
local pc_screen = require(str_pcscreen)
local pc_widget = c_util:GetFnEnv(pc_screen._BuildPurchasePanel).PurchaseWidget
if not pc_widget then
    return
end
local __ctor = pc_widget._ctor
pc_widget._ctor = function(self, ...)
    local ret = __ctor(self, ...)
    local _OnGainFocus = self.OnGainFocus
    self.OnGainFocus = function(w, ...)
        OnFocus(w)
        return _OnGainFocus(w, ...)
    end

    self.tip_button = self.root:AddChild(h_util:CreateImageButton{
        prefab = "weave_filter_on",
        pos = {-170, -57},
        size = 45,
        hover = "购买建议",
        hover_meta = {
            offset_y = 45
        },
        fn = function()
            fn_tip(self)
        end
    })
    return ret
end

AddClassPostConstruct(str_pcscreen, function()
    
    if info_best then
        return
    end
    local value_best = -1
    t_util:IPairs(TheItems:GetIAPDefs(), function(iap)
        local info = Getinfo(iap)
        if info.value > value_best then
            info_best = info
            value_best = info.value
        end
    end)
end)
