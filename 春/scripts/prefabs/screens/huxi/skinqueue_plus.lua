local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ItemImage = require "widgets/redux/itemimage"
local h_util = require "util/hudutil"
local t_util = require "util/tableutil"
local UIAnim = require "widgets/uianim"
local m_util = require "util/modutil"
local u_util = require "util/userutil"
local i_util = require "util/inpututil"

local units_per_row = 2.7
local num_rows = math.ceil(19 / units_per_row)
local dialog_size_x = 750
local row_height = 25 * units_per_row
local row_width = dialog_size_x
local dialog_size_y = row_height * (num_rows + 0.25)
local btn_y = -300

local DATA = {
    {
        id = "dupes",
        chs = "重复皮肤信息",
        x = -390,
        fn = function(self, info)
            self:BuildAmount()
            self.btn_queue:Enable()
            self.btn_queue:SetHoverText("点击左侧条目\n可移出自动拆解名单！", {font_size = 30, offset_y = 150})
            self.btn_queue:SetText("拆解重复皮肤")
        end,
        click = function(self, line, prefab)
            t_util:Add(self.prefabs_dupe, prefab)
            self:BuildAmount()
            self.scroll_list:SetItemsData(t_util:IPairFilter(self.dupes, function(line)
                return not table.contains(self.prefabs_dupe, line.prefab) and line
            end))
        end
    },{
        id = "shops",
        chs = "市场可交易皮肤",
        x = -150,
        fn = function(self, info)
            self.content:SetString("可在Steam市场进行出售，\n或者在交易小店九合一，\n因而不会被自动拆解。")
            self.btn_queue:SetHoverText("请先切换到【重复皮肤信息】", {font_size = 30, offset_y = 150})
            self.btn_queue:SetText("尚不可用")
            self.btn_queue:Disable()
        end
    },{
        id = "zeros",
        chs = "零线轴皮肤",
        x = 100,
        fn = function(self, info)
            self.content:SetString("参加各种活动或免费的皮肤,\n因为拆解了也没有线轴,\n所以不会被自动拆解。")
            self.btn_queue:SetText("尚不可用")
            self.btn_queue:SetHoverText("请先切换到【重复皮肤信息】", {font_size = 30, offset_y = 150})
            self.btn_queue:Disable()
        end
    }
}

local SQ = Class(Screen, function(self)
    Screen._ctor(self, "SkinQueuePlus")

    self.bg = self:AddChild(TEMPLATES.BackgroundTint(.9))
    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    
    self.back_button = self.root:AddChild(TEMPLATES.BackButton(function()
        TheFrontEnd:PopScreen()
    end))
    
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(dialog_size_x, dialog_size_y))
    self.dialog.top:Hide()
    self.dialog:SetPosition(-170, 30)
    
    self.title = self.dialog:AddChild(Text(HEADERFONT, 30, "重复皮肤信息", UICOLOURS.GOLD_SELECTED))
    self.title:SetPosition(0, 300)
    
    
    self:LoadData()
    
    self:BuildAmount()

    
    self:BuildGrid()

    
    
    self:BuildQueueBtn()

    
    self:BuildBtns()

    
    self.btn_dupes.onclick()
end)

local function HGift(prefab)
    local w = UIAnim()
    w:GetAnimState():SetBuild("skingift_popup") 
    w:GetAnimState():SetBank("gift_popup") 
    w.banner = w:AddChild(Image("images/giftpopup.xml", "banner.tex"))
    w.banner:SetPosition(0, -200, 0)
    
    w.text_up = w.banner:AddChild(Text(HEADERFONT, 45, "皮肤预览", UICOLOURS.GOLD_SELECTED))
    w.text_up:SetPosition(0, 370, 0)
    w.text_down = w.banner:AddChild(Text(UIFONT, 55))
    w.text_down:SetPosition(0, -10, 0)
    w.text_down:SetTruncatedString(GetSkinName(prefab), 500, 35, true)
    w.text_down:SetColour(GetColorForItem(prefab))
    w:GetAnimState():OverrideSkinSymbol("SWAP_ICON", GetBuildForItem(prefab), "SWAP_ICON")
    w:GetAnimState():PushAnimation("skin_loop")
    w:SetClickable(false)
    w:SetScale(.45)
    w:SetPosition(440, 180)
    return w
end

function SQ:BuildQueueBtn()
    local btn = self.root:AddChild(TEMPLATES.StandardButton(function()
        
        
        local function cb()
            local ui = require "widgets/huxi/hx_skinqueue"
            if ui then
                ui(self.prefabs_dupe)
            end
        end
        
        local mods = i_util:GetModsCS()
        if not t_util:IGetElement(mods, function(mod)
            return not (mod.name:find("群鸟绘卷") or mod.author:find("呼吸"))
        end) or Mod_ShroomMilk.Setting.SkipQueueCheck or m_util:IsMilker() then
            h_util:CreatePopupWithClose("免责声明", "该功能未经大量测试，如造成任何损失请您自行承担！\n另外，为避免拆解失败，使用前最好关闭其他模组。", {
                {
                    text = h_util.no,
                },{
                    text = "我已知晓风险并确认执行",
                    cb = cb,
                    dontpop = true,
                }
            })
        else
            h_util:CreatePopupWithClose(nil, "该功能使用前请先关闭其他模组")
        end
    end, "拆解重复皮肤", {300, 100}))
    self.btn_queue = btn
    btn.image:SetTint(.4, 1, .4, 1)
    btn:SetPosition(450, -200)
    
end


function SQ:BuildBtns()
    t_util:IPairs(DATA, function(info)
        local btn = self.root:AddChild(TEMPLATES.StandardButton(function()
            self.title:SetString(info.chs)
            self:LoadData()
            local data = self[info.id]
            self.scroll_list:SetItemsData(data)
            self:Preview(data[1] and data[1].prefab)
            if info.fn then
                info.fn(self, info)
            end
        end, 
        info.chs, {180, 50}))
        self["btn_"..info.id] = btn
        btn:SetPosition(info.x or 0, info.y or btn_y)
    end)
    self.btn_dupes:SetHoverText("点击上方条目\n可移出自动拆解名单！", {font_size = 30, offset_y = 150})
end
 

function SQ:BuildAmount()
    local now = TheInventory:GetCurrencyAmount()
    local content = "您现有 ".. now .." 线轴，\n"
    local count = 0
    t_util:IPairs(self.dupes, function(line)
        if not table.contains(self.prefabs_dupe, line.prefab) then
            count = (line.count-1)*line.spool + count
        end
    end)
    content = content.. "待分解 "..count.. " 线轴，\n"
    content = content.. "合计 "..(count+now).." 线轴。"
    if self.content then
        self.content:Kill()
    end
    self.content = self.root:AddChild(Text(DIALOGFONT, 40, content, RGB(222, 222, 99)))
    self.content:SetPosition(460, -50)
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
    w.widgets.skinname._position = {x = x, y = 10, w = 400 }
    w.widgets.count = w.widgets:AddChild(Text(CHATFONT, 22))
    w.widgets.count:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    w.widgets.count._position = {x = x, y = -13, w = 570 }
    local button_x = row_width - spacing - 20
    
    w.widgets.spool = w.widgets:AddChild(Text(CHATFONT, 40))
    w.widgets.spool:SetColour(UICOLOURS.HIGHLIGHT_GOLD)
    w.widgets.spool._position = {x = button_x, y = 0, w = 400 }
    
    w.widgets.rarity = w.widgets:AddChild(Text(HEADERFONT, 40))
    w.widgets.rarity._position = { x = button_x - 2.5 * row_height, y = 0, w = 400 }
    return w
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

function SQ:Preview(prefab)
    if self.preview then
        self.preview:Kill()
    end
    if not prefab then return end
    self.preview = self.root:AddChild(HGift(prefab))
end
function SQ:BuildGrid()
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
        w.widgets.skin:SetOnClick(function()
            self:Preview(prefab)
        end)
        local rarity_cn, name, rgb = GetModifiedRarityStringForItem(prefab), GetSkinName(prefab), GetColorForItem(prefab)
        w.widgets.skinname:SetColour(rgb)
        SetTruncatedLeftJustifiedString(w.widgets.skinname, name)
        SetTruncatedLeftJustifiedString(w.widgets.count, "数量：" .. data.count)
        SetTruncatedRightJustifiedString(w.widgets.spool, data.spool * data.count .. " 线轴")
        SetTruncatedRightJustifiedString(w.widgets.rarity, rarity_cn .. " 品质")
        w.widgets.rarity:SetColour(rgb)
        w.bg:SetOnClick(function()
            self:Preview(prefab)
            local fn = t_util:IGetElement(DATA, function(info)
                return info.id == data.cate and info.click
            end)
            if fn then
                fn(self, data, prefab)
            end
        end)
    end
    self.scroll_list = self.dialog:AddChild(TEMPLATES.ScrollingGrid({}, {
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
    self.scroll_list:SetPosition(-20, 0)
end


function SQ:LoadData()
    self.prefabs_dupe = {}
    local skins = u_util:GetSkinsData()
    t_util:IPairs(DATA, function(info)
        self[info.id] = skins[info.id]
    end)
end

return SQ