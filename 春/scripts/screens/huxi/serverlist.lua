local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local t_util = require "util/tableutil"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local h_util = require "util/hudutil"
local s_mana = require "util/settingmanager"

local units_per_row = 2.7
local num_rows = math.ceil(19 / units_per_row)
local dialog_size_x = 830
local dialog_width = dialog_size_x + (60 * 2) 
local row_height = 25 * units_per_row
local row_width = dialog_width * 0.9
local dialog_size_y = row_height * (num_rows + 0.25)

local title_table = {
    history = "历史游玩服务器",
    mine = "我的收藏服务器",
    setting = "功能设置",
}


local save_id = "sw_server"
local star_id = save_id.."star"
local star_list = s_mana:GetSettingList(star_id, true)

local ServerList = Class(Screen, function(self, last_list, func_save, func_setting)
    Screen._ctor(self, "SkinQueue")

    self.bg = self:AddChild(TEMPLATES.BackgroundTint())
    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    self.func_save = type(func_save) == "function" and func_save or function()end
    self.func_setting = type(func_setting) == "function" and func_setting or function()end

    self.back_button = self.root:AddChild(TEMPLATES.BackButton(function()
        TheFrontEnd:PopScreen()
    end))

    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(dialog_size_x, dialog_size_y))
    self.dialog:SetPosition(-120, 30)

    self.title = self.root:AddChild(Text(HEADERFONT, 30, "啦啦啦，我是标题", UICOLOURS.GOLD_SELECTED))
    self.title:SetPosition(-120, 340)
    self.null = self.dialog:AddChild(Text(TITLEFONT, 30, "没有服务器信息，快去玩游戏！", UICOLOURS.IVORY))
    self.history = last_list or {}
    table.sort(self.history, function(a, b)
        return a.time > b.time
    end)
    self:Init()

    local i = 0
    t_util:Pairs(title_table, function(id, str)
        self.dialog:AddChild(TEMPLATES.StandardButton(function()
            self:Init(id)
        end, str, {180, 50})):SetPosition(-240+(i*250), -340)
        i = i+1
    end)
end)


function ServerList:LoadData()
    self.mine = s_mana:GetSettingList(star_id, true)
    table.sort(self.mine, function (a, b)
        return a.time > b.time
    end)
end
function ServerList:SaveServer(data)
    local star_list = s_mana:GetSettingList(star_id, true)
    local id
    for pos, idata in ipairs(star_list)do
        if data.ip == idata.ip and data.port == idata.port then
            idata.time = data.time
            id  = pos
            break
        end
    end
    for pos, idata in ipairs(self.history)do
        if data.ip == idata.ip and data.port == idata.port then
            idata.time = data.time
            idata.star = data.star
            break
        end
    end
    if data.star then
        if not id then
            table.insert(star_list, data)
        end
    else
        if id then
            table.remove(star_list, id)
        end
    end
    s_mana:SaveSettingList(star_id, star_list)
    self.func_save()
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

    w.widgets.skin = w.widgets:AddChild(Image())
    x = x + row_height / 2
    w.widgets.skin:SetPosition(x, 0)
    x = x + row_height / 2 + spacing

    w.widgets.skinname = w.widgets:AddChild(Text(HEADERFONT, 30))
    w.widgets.skinname._position = {
        x = x,
        y = 10,
        w = 400
    }
    w.widgets.skinname:SetColour(UICOLOURS.GOLD)

    w.widgets.time = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.time:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    w.widgets.time._position = {
        x = x,
        y = -13,
        w = 570
    }
    local x3, t3 = h_util:GetPrefabAsset("goto_url")
    local x2, t2 = h_util:GetPrefabAsset("preset_linked")
    local x1, t1 = h_util:GetPrefabAsset("player_info")
    
    w.widgets.guid = w.widgets:AddChild(TEMPLATES.IconButton(x3, t3, "模拟直连", false, false,function()end, { offset_y = 65 }))
    w.widgets.guid:SetPosition(row_width-0.5*row_height, 0)
    w.widgets.guid:SetScale(.8, .8, .8)
    w.widgets.guid:Hide()
    w.widgets.ip = w.widgets:AddChild(TEMPLATES.IconButton(x2, t2, "IP 直连", false, false,function()end, { offset_y = 65 }))
    w.widgets.ip:SetPosition(row_width-1.3*row_height, 0)
    w.widgets.ip:SetScale(.8, .8, .8)
    w.widgets.ip:Hide()
    w.widgets.info = w.widgets:AddChild(TEMPLATES.IconButton(x1, t1, "查看服务器信息", false, false,function()end, { offset_y = 65 }))
    w.widgets.info:SetPosition(row_width-2.1*row_height, 0)
    w.widgets.info:SetScale(.8, .8, .8)
    w.widgets.info:Hide()
    w.widgets.star = w.widgets:AddChild(ImageButton())
    w.widgets.star:SetPosition(row_width-2.9*row_height, 0)
    w.widgets.star:SetHoverText("收藏/取消收藏")
    w.widgets.star:Hide()
    return w
end

local function widget_apply(context, w, data, index)
    if not (w and data and data.ip and data.port) then
        return
    end
    local xml, tex = h_util:GetPrefabAsset(tostring(data.style).."_small")
    if not xml then
        xml, tex =  h_util:GetRandomSkin(true)
    end
    w.widgets.skin:SetTexture(xml, tex)
    w.widgets.skin:SetSize(h_util.btn_size, h_util.btn_size)
    SetTruncatedLeftJustifiedString(w.widgets.skinname, data.name)
    SetTruncatedLeftJustifiedString(w.widgets.time, "上次游玩于 " .. os.date("%Y年 %m月 %d日 %H:%M", data.time))
    if not data.ip then return end
    w.widgets.info:SetOnClick(function()
        local str = "地址：".." "..data.ip..":"..data.port.."\n"
        if data.pwd and data.pwd ~= "" then
            str = str.."密码："..data.pwd.."\n"
        end
        str = str.."GUID："..data.guid
        h_util:CreatePopupWithClose(data.name, str)
    end)
    w.widgets.info:Show()

    
    w.widgets.guid:SetOnClick(function()
        local QuickJoin = Mod_ShroomMilk.Func.QuickJoin
        if QuickJoin then
            QuickJoin({pwd = data.pwd, guid = data.guid})
        end
        data.time = os.time()
        context.screen:SaveServer(data)
    end)
    w.widgets.guid:Show()

    w.widgets.ip:SetOnClick(function()
        local QuickJoin = Mod_ShroomMilk.Func.QuickJoin
        if QuickJoin then
            QuickJoin({pwd = data.pwd, ip = data.ip, port = data.port, type = "ip"})
        end
        data.time = os.time()
        context.screen:SaveServer(data)
    end)
    w.widgets.ip:Show()

    local function SetStar(star)
        w.widgets.star:SetTextures("images/global_redux.xml", star and "star_checked.tex" or "star_uncheck.tex", nil, star and "star_uncheck.tex" or "star_checked.tex", nil, nil, {0.75,0.75}, {0, 0})
    end
    w.widgets.star:SetOnClick(function()
        data.star = not data.star
        SetStar(data.star)
        context.screen:SaveServer(data)
    end)
    SetStar(data.star)
    w.widgets.star:Show()
end

function ServerList:Init(id)
    if id == "setting" then
        return self.func_setting()
    end

    if self.scroll_list then
        self.scroll_list:Kill()
    end
    id = id or "history"

    self.title:SetString(title_table[id])

    self:LoadData()
    local data = self[id]
    if not data or #data == 0 then
        return self.null:Show()
    else
        self.null:Hide()
    end
    
    self.scroll_list = self.dialog:AddChild(TEMPLATES.ScrollingGrid(data, {
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
end

return ServerList