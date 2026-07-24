local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local t_util = require "util/tableutil"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ItemImage = require "widgets/redux/itemimage"
local HGift = require "widgets/huxi/huxi_gift"
local h_util = require("util/hudutil")

local units_per_row = 2.7
local num_rows = math.ceil(19 / units_per_row)
local dialog_size_x = 830
local dialog_width = dialog_size_x + (60 * 2) 
local row_height = 25 * units_per_row
local row_width = dialog_width * 0.9
local dialog_size_y = row_height * (num_rows + 0.25)
local str_t = {
    dupes = "重复皮肤信息",
    zeros = "零线轴皮肤",
    shops = "市场交易皮肤"
}
local str_ing = "正在分解..."

local SkinQueue = Class(Screen, function(self, skindata)
    Screen._ctor(self, "SkinQueue")

    self.bg = self:AddChild(TEMPLATES.BackgroundTint())
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.back_button = self.root:AddChild(TEMPLATES.BackButton(function()
        TheFrontEnd:PopScreen()
    end))
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(dialog_size_x, dialog_size_y))
    self.dialog:SetPosition(-120, 30)
    self:LoadData()

    self.title = self.root:AddChild(Text(HEADERFONT, 30, "重复皮肤信息", UICOLOURS.GOLD_SELECTED))
    self.title:SetPosition(-120, 340)
    self.null = self.dialog:AddChild(Text(TITLEFONT, 30, "没有相关皮肤信息", UICOLOURS.IVORY))
    self:Init()

    local i = 0
    t_util:Pairs(str_t, function(id, str)
        self.dialog:AddChild(TEMPLATES.StandardButton(function()
            self:Init(id)
        end, str, {180, 50})):SetPosition(-240+(i*250), -340)
        i = i+1
    end)

    self.btn = self.dialog:AddChild(TEMPLATES.StandardButton(function()
        if self.btn:GetText() == str_ing then
            if TheGlobalInstance.skinqueue then
                TheGlobalInstance.skinqueue:Cancel()
                TheGlobalInstance.skinqueue = nil
            end
            return self.btn:SetText("已停止分解")
        end
        self:StartBarter()
    end, "分解重复皮肤", {180, 50}))
    self.btn:SetPosition(-240+(i*250), -340)

    
    self.log = self.root:AddChild(Text(BODYTEXTFONT, 30, "", UICOLOURS.SLATE))
    self.log:SetPosition(h_util:ToSize(470, -100))
    self.log:SetHAlign(ANCHOR_LEFT)
end)

function SkinQueue:LoadData()
    self.dupes, self.shops, self.zeros = {}, {}, {}
    t_util:Pairs(GetOwnedItemCounts(), function(item_key, item_count)
        local spools = TheItems:GetBarterSellPrice(item_key) 
        local inshop = IsItemMarketable(item_key) 
        if item_count > 1 and spools > 0 and not inshop then
            table.insert(self.dupes, {
                prefab = item_key,
                count = item_count - 1,
                spool = spools
            })
        end
        if inshop then
            table.insert(self.shops, {
                prefab = item_key,
                count = item_count,
                spool = spools
            })
        end
        if spools == 0 then
            table.insert(self.zeros, {
                prefab = item_key,
                count = item_count,
                spool = spools
            })
        end
    end)
    local function sort(a, b)
        if a.spool == b.spool then
            return a.count > b.count
        else
            return a.spool > b.spool
        end
    end
    table.sort(self.dupes, sort)
    table.sort(self.shops, sort)
    table.sort(self.zeros, sort)
end

local function SetTruncatedLeftJustifiedString(txt, str)
    txt:SetTruncatedString(str or "", txt._position.w, nil, true)
    local width, height = txt:GetRegionSize()
    txt:SetPosition(txt._position.x + width / 2, txt._position.y)
end
local function SetTruncatedRightJustifiedString(txt, str)
    txt:SetTruncatedString(str or "", txt._position.w, nil, true)
    local width, height = txt:GetRegionSize()
    txt:SetPosition(txt._position.x - width / 2, txt._position.y)
end
local function widget_constructor(context, i)
    local top_y = -12
    local w = Widget("skinline")
    w.root = w:AddChild(Widget("skinline_root"))
    w.bg = w.root:AddChild(TEMPLATES.ListItemBackground(row_width, row_height))
    w.bg:SetOnGainFocus(function()
        context.screen.scroll_list:OnWidgetFocus(w)
    end)

    w.widgets = w.root:AddChild(Widget("skinline-data_root"))
    w.widgets:SetPosition(-row_width / 2, 0)

    local spacing = 15
    local x = spacing

    w.widgets.skin = w.widgets:AddChild(ItemImage(Profile, context.screen))
    x = x + row_height / 2
    w.widgets.skin:SetPosition(x, 0)
    x = x + row_height / 2 + spacing

    w.widgets.skinname = w.widgets:AddChild(Text(HEADERFONT, 30))
    w.widgets.skinname._position = {
        x = x,
        y = 10,
        w = 400
    }

    w.widgets.count = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.count:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    w.widgets.count._position = {
        x = x,
        y = -13,
        w = 570
    }

    local button_x = row_width - spacing - 20
    w.widgets.spool = w.widgets:AddChild(Text(CHATFONT, 40))
    w.widgets.spool:SetColour(UICOLOURS.HIGHLIGHT_GOLD)
    w.widgets.spool._position = {
        x = button_x,
        y = 0,
        w = 400
    }

    w.widgets.rarity = w.widgets:AddChild(Text(HEADERFONT, 40))
    w.widgets.rarity._position = {
        x = button_x - 4 * row_height,
        y = 0,
        w = 400
    }
    return w
end
local function widget_apply(context, w, data, index)
    if not w then
        return
    end
    local prefab = data and data.prefab
    if not prefab then
        w.root:Hide()
        return
    end
    w.root:Show()
    w.widgets.skin:SetItem(GetTypeForItem(prefab), prefab)
    local function preview()
        if context.screen.preview then
            context.screen.preview:Kill()
        end
        context.screen.preview = context.screen:AddChild(HGift(prefab, true))
    end
    w.widgets.skin:SetOnClick(preview)
    local rarity_cn, name, rgb = GetModifiedRarityStringForItem(prefab), GetSkinName(prefab), GetColorForItem(prefab)
    w.widgets.skinname:SetColour(rgb)
    SetTruncatedLeftJustifiedString(w.widgets.skinname, name)
    SetTruncatedLeftJustifiedString(w.widgets.count, "数量：" .. data.count)

    SetTruncatedRightJustifiedString(w.widgets.spool, data.spool * data.count .. " 线轴")

    SetTruncatedRightJustifiedString(w.widgets.rarity, rarity_cn .. " 品质")
    w.widgets.rarity:SetColour(rgb)

    w.bg:SetOnClick(function()
        preview()
        local flag
        for i, d in ipairs(context.screen.dupes) do
            if d == data then
                table.remove(context.screen.dupes, i)
                flag = true
                break
            end
        end
        if flag then
            context.screen:Init()
        end
    end)
end
function SkinQueue:Init(id)
    id = id or "dupes"
    if self.scroll_list then
        self.scroll_list:Kill()
    end
    self.scroll_list = self.dialog:AddChild(TEMPLATES.ScrollingGrid(self[id], {
        scroll_context = {
            screen = self
        },
        widget_width = row_width,
        widget_height = row_height,
        num_visible_rows = num_rows,
        num_columns = 1,
        item_ctor_fn = widget_constructor,
        apply_fn = widget_apply,
        scrollbar_offset = 20,
        scrollbar_height_offset = -60
    }))
    self.scroll_list:SetPosition(-20, -10)

    if #self[id] == 0 then
        self.null:Show()
    else
        self.null:Hide()
    end

    self.title:SetString(str_t[id])

    
    local count = 0
    t_util:IPairs(self.dupes, function(data)
        count = data.count*data.spool + count
    end)
    local now = TheInventory:GetCurrencyAmount()
    local content = "您现有 ".. now .." 线轴，\n"
    content = content.. "待分解 "..count.. " 线轴，\n"
    content = content.. "合计 "..(count+now).." 线轴。"
    if self.content then
        self.content:Kill()
    end
    self.content = self.root:AddChild(Text(DIALOGFONT, 30, content, UICOLOURS.HIGHLIGHT_GOLD))
    self.content:SetPosition(h_util:ToSize(470, 0))
    self.content:SetHAlign(ANCHOR_LEFT)
end

function SkinQueue:StartBarter()
    local function fn()
        if TheGlobalInstance.skinqueue then
            TheGlobalInstance.skinqueue:Cancel()
        end
        TheGlobalInstance.skinqueue = TheGlobalInstance:DoPeriodicTask(1, function()
            local index, data = next(self.dupes)
            if index and data then
                local prefab = data.prefab
                local name_skin = GetSkinName(prefab)
                local item_count = GetOwnedItemCounts()[prefab] or 0
                local function func()
                    item_count = GetOwnedItemCounts()[prefab] or 0
                    if item_count == 1 then
                        self.log:SetString("完美分解！"..name_skin)
                        table.remove(self.dupes, index)
                        self:Init()
                    elseif item_count == 0 then
                        self.log:SetString("完蛋，多分解了！".. name_skin)
                        table.remove(self.dupes, index)
                        self:Init()
                    end
                end
                if item_count > 1 then
                    self.log:SetString("尝试分解 "..name_skin..", \n线轴："..data.spool..", 任务数量："..item_count-1)
                    local id = GetFirstOwnedItemId(prefab)
                    TheItems:BarterLoseItem(id, data.spool, function (success, status)
                        if success then
                            TheGlobalInstance:DoTaskInTime(0, function ()
                                h_util:PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/unweave")
                                func()
                            end)
                        else
                            self.log:SetString("分解失败！")
                        end
                    end)
                else
                    func()
                end
            else
                self.log:SetString("没有可以分解的队列")
                TheGlobalInstance.skinqueue:Cancel()
                TheGlobalInstance.skinqueue = nil
            end
        end)
        self.btn:SetText(str_ing)
    end

    h_util:CreatePopupWithClose("免责声明", "该功能未经大量测试，如造成任何损失请您自行承担！\n这边推荐您还是订阅其他模组。",{
        {
            text = "取消"
        },{
            text = "订阅推荐模组",
            cb = function()
                VisitURL("https://steamcommunity.com/sharedfiles/filedetails/?id=1557935632")
            end
        },{
            text = "我同意免责并立即分解",
            cb = fn,
        },
    })
end

return SkinQueue
