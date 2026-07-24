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
local WTC = require("data/valuetable").weekday_en_to_cn
local h_util = require("util/hudutil")

local units_per_row = 2.7
local num_rows = math.ceil(19 / units_per_row)
local dialog_size_x = 830
local dialog_width = dialog_size_x + (60*2) 
local row_height = 25 * units_per_row
local row_width = dialog_width*0.9
local dialog_size_y = row_height*(num_rows + 0.25)


local HisSkin = Class(Screen, function(self, skindata)
    Screen._ctor(self, "SkinHistory")
    self.data = skindata or {}
    table.sort(self.data, function(a, b)
        return (type(a.time) == "number" and a.time or 0) > (type(b.time) == "number" and b.time or 0)
    end)
    
	self.bg = self:AddChild(TEMPLATES.BackgroundTint())
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.back_button = self.root:AddChild(TEMPLATES.BackButton(function()
        TheFrontEnd:PopScreen()
    end))
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(dialog_size_x, dialog_size_y))
    self.dialog:SetPosition(-120, 30)

    self.title = self.root:AddChild(Text(HEADERFONT, 30, "历史礼物数据", UICOLOURS.GOLD_SELECTED))
	self.title:SetPosition(-120, 340)

    if #self.data == 0 then
        self.null = self.dialog:AddChild(Text(TITLEFONT, 30, "啥礼物也没有", UICOLOURS.IVORY))
    end
    self:Init()
    
    
    local now = os.time()
    
    local today_weekday = tonumber(os.date("%w"))
    
    local days_to_last_friday = (today_weekday + 2) % 7
    
    local last_friday_time = os.time{year=os.date("%Y", now), month=os.date("%m", now), day=os.date("%d", now) - days_to_last_friday, hour=5, min=45, sec=0}
    
    if today_weekday == 5 and os.date("%H:%M", now) > "05:45" then
        last_friday_time = last_friday_time - 24 * 60 * 60 * 7
    end
    
    local count_week, count_all, count = 0, 0, 0
    local cate = {}
    t_util:IPairs(self.data, function(data)
        local time = tonumber(data.time)
        if time > last_friday_time then
            if data.type == "每周礼物" then
                count_week = count_week + 1
            end
            count_all = count_all + 1
        end

        local prefab = data and data.skin
        if not prefab then
            return
        end
        local rarity_cn, rgb =  GetModifiedRarityStringForItem(prefab), GetColorForItem(prefab)
        if rarity_cn and rgb and table.contains({"每周礼物", "每日礼物"}, data.type) then
            count = count + 1
            if cate[rarity_cn] and cate[rarity_cn].count then
                cate[rarity_cn].count = cate[rarity_cn].count + 1
            else
                cate[rarity_cn] = {count = 1, rgb = rgb}
            end
        end
    end)

    local cate_all = t_util:PairToIPair(cate, function(name, data)
        return {name = name, count = data.count, rgb = data.rgb}
    end)
    table.sort(cate_all, function(a, b)
        return a.count > b.count
    end)

    local days_to_next_friday = (5 - today_weekday) % 7
    
    if today_weekday == 5 then
        days_to_next_friday = 7
    end
    days_to_next_friday = days_to_next_friday - 1
    
    local content = "本周您一共获取了 "..count_all.. " 个礼物。\n"
    content = content.. "每周礼物您获得了 "..count_week.." 个，\n还剩 "..(8-count_week).." 个每周礼物。\n"
    content = content.. "截至下个周五，\n您共有 "..(8-count_week).."+"..days_to_next_friday.." 个礼物等待领取。"

    self.content = self.root:AddChild(Text(DIALOGFONT, 30, content, UICOLOURS.GOLD_UNIMPORTANT))
    self.content:SetPosition(h_util:ToSize(490, -180))
    self.content:SetHAlign(ANCHOR_LEFT)

    for i, data in ipairs(cate_all)do
        local num = string.format("%.2f %%", data.count/count*100)
        local ui_info = self.root:AddChild(Text(DIALOGFONT, 30, data.name.."："..num, data.rgb))
        ui_info:SetPosition(h_util:ToSize(490, -100+i*30))
    end
end)

local function widget_constructor(context, i)
    local top_y = -12
    local w = Widget("skinline")
	w.root = w:AddChild(Widget("skinline_root"))
    w.bg = w.root:AddChild(TEMPLATES.ListItemBackground(row_width, row_height))
	w.bg:SetOnGainFocus(function() context.screen.scroll_list:OnWidgetFocus(w) end)

    w.widgets = w.root:AddChild(Widget("skinline-data_root"))
	w.widgets:SetPosition(-row_width/2, 0)

	local spacing = 15
	local x = spacing

    w.widgets.skin = w.widgets:AddChild(ItemImage(Profile, context.screen))
    x = x + row_height/2
    w.widgets.skin:SetPosition(x , 0)
	x = x + row_height/2 + spacing

	w.widgets.playername = w.widgets:AddChild(Text(HEADERFONT, 30))
	w.widgets.playername._position = { x = x, y = 10, w = 400 }

    
    w.widgets.date = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.date:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
	w.widgets.date._position = { x = x, y = -13, w = 570 }

    local button_x = row_width - spacing - 20
    w.widgets.gifttype = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.gifttype:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
	w.widgets.gifttype._position = { x = button_x, y = 12, w = 300 }
    w.widgets.week = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.week:SetColour(UICOLOURS.HIGHLIGHT_GOLD)
	w.widgets.week._position = { x = button_x, y = -13, w = 125 }

    w.widgets.rarity =  w.widgets:AddChild(Text(HEADERFONT, 40))
	w.widgets.rarity._position = { x = button_x - 3*row_height, y = 0, w = 400 }
    return w
end
local function SetTruncatedLeftJustifiedString(txt, str)
	txt:SetTruncatedString(tostring(str), txt._position.w, nil, true)
	local width, height = txt:GetRegionSize()
	txt:SetPosition(txt._position.x + width/2, txt._position.y)
end
local function SetTruncatedRightJustifiedString(txt, str)
	txt:SetTruncatedString(tostring(str), txt._position.w, nil, true)
	local width, height = txt:GetRegionSize()
	txt:SetPosition(txt._position.x - width/2, txt._position.y)
end
local function widget_apply(context, w, data, index)
    if not w then return end
    local prefab = data and data.skin
    if not prefab then w.root:Hide() return end
    w.root:Show()
    w.widgets.skin:SetItem(GetTypeForItem(prefab),prefab)
    local function preview()
        if context.screen.preview then
            context.screen.preview:Kill()
        end
        context.screen.preview = context.screen:AddChild(HGift(prefab, true))
    end
    w.widgets.skin:SetOnClick(preview)
    w.bg:SetOnClick(preview)
    
    local rarity_cn, name, rgb =  GetModifiedRarityStringForItem(prefab), GetSkinName(prefab), GetColorForItem(prefab)
    w.widgets.playername:SetColour(rgb)
    SetTruncatedLeftJustifiedString(w.widgets.playername, name)

    local time = os.date("%Y年 %m月 %d日 %H:%M:%S", data.time)
    SetTruncatedLeftJustifiedString(w.widgets.date, time)
    
    SetTruncatedRightJustifiedString(w.widgets.gifttype, data.type) 
    local en_week = os.date("%A", data.time)
    local cn_week = en_week and WTC[en_week]
    if cn_week then
        SetTruncatedRightJustifiedString(w.widgets.week, cn_week) 
    end

    SetTruncatedRightJustifiedString(w.widgets.rarity, rarity_cn.." 品质")
    w.widgets.rarity:SetColour(rgb)
end
function HisSkin:Init()
    self.scroll_list = self.dialog:AddChild(TEMPLATES.ScrollingGrid(
        self.data,
        {
            scroll_context = {
                screen = self,
            },
            widget_width  = row_width,
            widget_height = row_height,
            num_visible_rows = num_rows,
            num_columns = 1,
            item_ctor_fn = widget_constructor,
            apply_fn = widget_apply,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60
        }
    ))
    self.scroll_list:SetPosition(-20, -10)
end




return HisSkin