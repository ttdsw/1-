local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"
local ItemImage = require "widgets/redux/itemimage"
local UIAnim = require "widgets/uianim"
local h_util = require "util/hudutil"
local t_util = require "util/tableutil"
local m_util = require "util/modutil"
local u_util = require "util/userutil"
local TPS = {
    beard = "beards",
}


local SQ = Class(Widget, function(self, prefabs)
    Widget._ctor(self, "skin_queue_widget")
    
    self.prefabs = t_util:MergeList(prefabs)
    local skins = self:GetSkins()
    self.count_start = #skins

    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.black = self.root:AddChild(TEMPLATES.BackgroundTint(1))

    self.width, self.height = 700, 700
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(self.width, self.height))
    
    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    self.dialog:SetBackgroundTint(r,g,b, 1)
    self.time_dt = 0
    self.time_flush = 1
    self.posx_start = 300
    self.posy_start = 130
    self.fontsize_count = 35

    self.color_yellow = RGB(222, 222, 99)
    self.color_blue = RGB(0, 200, 255)
    self.color_red = RGB(220, 20, 60)

    
    self.widget_1 = self.dialog:AddChild(Widget("skin_queue_widget_1"))
    self.text_1 = self.dialog:AddChild(Text(HEADERFONT, 50, "按下Esc退出拆解...", self.color_blue))
    self.text_1:SetHAlign(ANCHOR_LEFT)
    self.text_1:SetRegionSize(self.width, 55)
    self.text_1:SetPosition(-self.posx_start+self.width/2+20, -self.posy_start)

    if self.count_start == 0 then
        self:AutoError("没有可以分解的皮肤,\n页面即将关闭({num})...", 4)
    else
        
        self.anim_skin = self.widget_1:AddChild(self:BuildPreview(skins[1]))
        local shift_anim = self.posy_start - 2*self.fontsize_count
        self.anim_skin:SetPosition(150, shift_anim)
        self.anim_bar = self.widget_1:AddChild(self:BuildBar())
        self.anim_bar:SetPosition(0, 230)

        for i = 1, 5 do
            local img = self.widget_1:AddChild(Image("images/button_icons.xml", "weave_filter_on.tex"))
            self["image_"..i] = img
            img:SetSize(self.fontsize_count-2, self.fontsize_count-2)
            img:SetPosition(-self.posx_start, self.posy_start - (i-1)*self.fontsize_count)
        end
        for i = 2, 6 do
            local text = self.widget_1:AddChild(Text(CHATFONT, self.fontsize_count, ""))
            self["text_"..i] = text
            text:SetHAlign(ANCHOR_LEFT)
            text:SetRegionSize(self.width, self.fontsize_count + 5)
            text:SetPosition(-self.posx_start+self.width/2+20, self.posy_start - (i-2)*self.fontsize_count)
        end
        self.text_2:SetColour(self.color_yellow)
        self.text_3:SetColour(self.color_yellow)
        self:Flush()
        self:StartUpdating()
    end
end)

function SQ:OnUpdate(dt)
    if TheInput:IsControlPressed(CONTROL_CANCEL) then
        self:Kill()
    elseif m_util:IsHuxi() and TheInput:IsControlPressed(CONTROL_SECONDARY) then
        self:Kill()
    end
    self.time_dt = self.time_dt + dt
    if self.time_dt > self.time_flush then
        self.time_dt = 0
        self:Flush()
    end
end

function SQ:AutoError(str, seconds)
    if self.error_flag then return end
    self.error_flag = true
    self.widget_1:Hide()
    str = str or "发生异常！\n页面正在自动关闭({num})..."
    seconds = seconds or 3
    local function SetNum(i)
        return function()
            self.text_1:SetString(subfmt(str, {num = i}))
        end
    end
    self.text_1:SetHAlign(ANCHOR_MIDDLE)
    self.text_1:SetRegionSize(self.width, 200)
    self.text_1:SetPosition(0, 0)
    self.text_1:SetColour(self.color_yellow)
    SetNum(seconds)()
    for i = 1, seconds-1 do
        self.inst:DoTaskInTime(i, SetNum(seconds - i))
    end
    self.inst:DoTaskInTime(seconds, function() self:Kill() end)
end

function SQ:Flush()
    if self.error_flag then return end
    local skins = self:GetSkins()
    local line = skins[1]
    if line then
        local spools_has, spools_pre = self:GetAmout(skins)
        self.text_2:SetString("正在拆解："..GetSkinName(line.prefab))
        self.text_3:SetString("价值线轴："..line.spool*(line.count-1).." 线轴")
        self.text_4:SetString("现有: "..spools_has.." 线轴")
        self.text_5:SetString("待分解: "..spools_pre.." 线轴")
        self.text_6:SetString("合计: "..spools_pre+spools_has.." 线轴")
        self.anim_bar:SetPercent((self.count_start-#skins)/self.count_start)
        self.anim_skin:SetPreview(line.prefab)

        local isPaused
        
        
        
        local screen = h_util:GetActiveScreen()
        
        if screen.name == "SkinQueuePlus" then
            TheFrontEnd:PopScreen()
        elseif screen.name == "PlayerSummaryScreen" then
            screen:OnSkinsButton()
        elseif screen.name == "CollectionScreen" then
            local str_btn = "beards" 
            local picker = str_btn and t_util:GetRecur(screen, "subscreener.sub_screens."..str_btn..".picker")
            if picker and picker.last_interaction_target then
                
                picker:_DoCommerce(line.prefab)
            else
                local fn = str_btn and t_util:GetRecur(screen, "subscreener.buttons."..str_btn..".onclick")
                if fn then
                    fn()
                else
                    return self:AutoError()
                end
            end
        elseif screen.name == "BarterScreen" then
            local title = screen.dialog.title:GetString()
            if title == STRINGS.UI.BARTERSCREEN.TITLE then
                local btn = t_util:IGetElement(t_util:GetRecur(screen, "dialog.actions.items") or {} , function(btn)
                    return btn.text and btn.text:GetString()==STRINGS.UI.BARTERSCREEN.COMMERCE_GRIND and btn
                end)
                if btn then
                    btn:ForceImageSize(h_util:ToPos(2, 2))
                    isPaused = true
                    local btn_cancel = t_util:IGetElement(t_util:GetRecur(screen, "dialog.actions.items") or {} , function(btn)
                        return btn.text and btn.text:GetString()==STRINGS.UI.BARTERSCREEN.CANCEL and btn
                    end)
                    if btn_cancel then
                        btn_cancel:Hide()
                    end
                else
                    return TheFrontEnd:PopScreen()
                end
            else
                local fn_btn = screen.item_key and screen.doodad_value and not screen.is_buying and t_util:IGetElement(t_util:GetRecur(screen, "dialog.actions.items") or {} , function(btn)
                    return btn.text and btn.text:GetString()==STRINGS.UI.BARTERSCREEN.COMMERCE_GRIND_DUPES and btn.onclick
                end)
                if fn_btn then
                    fn_btn()
                else
                    return TheFrontEnd:PopScreen()
                end
            end
        elseif screen.name == "PopupDialogScreen" then
            local title = screen.dialog.title:GetString()
            if title == "免责声明" then
                return TheFrontEnd:PopScreen()
            elseif title == STRINGS.UI.BARTERSCREEN.COMMERCE_GRIND_DUPES then
                local btn = t_util:IGetElement(t_util:GetRecur(screen, "dialog.actions.items") or {} , function(btn)
                    return btn.text and btn.text:GetString()==STRINGS.UI.POPUPDIALOG.OK and btn.inst and btn.inst.GUID and btn
                end)
                
                
                
                if btn then
                    btn:ForceImageSize(h_util:ToPos(2, 2))
                    isPaused = true
                else
                    return TheFrontEnd:PopScreen()
                end
            else
                return self:AutoError("错误页面1:"..screen.name.."\n页面正在自动关闭({num})...", 100)
            end
        elseif screen.name == "ItemServerContactPopup" then
            
        else
            return self:AutoError("错误页面2:"..screen.name.."\n页面正在自动关闭({num})...", 5)
        end

        local num_dot = math.ceil(GetTime()%10)
        local str_dot = ""
        for i = 1, num_dot do
            str_dot = str_dot.."."
        end
        if isPaused then
            self.text_1:SetColour(self.color_red)
            self.text_1:SetString("拆解被科雷暂停，点击屏幕继续拆解"..str_dot)
        else
            self.text_1:SetColour(self.color_blue)
            self.text_1:SetString("正在拆解, 按下Esc退出拆解"..str_dot)
        end
    else
        self:AutoError("全部拆解完成！\n页面即将关闭({num})", 5)
    end
end

function SQ:GetSkins()
    return table.reverse(t_util:IPairFilter(u_util:GetSkinsData().dupes, function(line)
        return not table.contains(self.prefabs, line.prefab) and line
    end))
end

function SQ:GetAmout(dupes)
    local now = TheInventory:GetCurrencyAmount()
    local count = 0
    t_util:IPairs(dupes, function(line)
        count = (line.count-1)*line.spool + count
    end)
    return now, count
end

function SQ:BuildPreview(line)
    local w = UIAnim()
    local prefab = line.prefab
    w:GetAnimState():SetBuild("skingift_popup") 
    w:GetAnimState():SetBank("gift_popup") 
    w.banner = w:AddChild(Image("images/giftpopup.xml", "banner.tex"))
    w.banner:SetPosition(0, -200, 0)
    
    w.text_up = w.banner:AddChild(Text(HEADERFONT, 45, "拆解预览", UICOLOURS.GOLD_SELECTED))
    w.text_up:SetPosition(0, 370, 0)
    w.text_down = w.banner:AddChild(Text(UIFONT, 55))
    w.text_down:SetPosition(0, -10, 0)
    w:GetAnimState():PushAnimation("skin_loop")
    w:SetScale(.4)

    w.SetPreview = function(ui, prefab)
        w.text_down:SetTruncatedString(GetSkinName(prefab), 500, 35, true)
        w.text_down:SetColour(line.spool > 100 and GetColorForItem(prefab) or UICOLOURS.WHITE)
        w:GetAnimState():OverrideSkinSymbol("SWAP_ICON", GetBuildForItem(prefab), "SWAP_ICON")
    end
    w:SetPreview(prefab)

    return w
end

function SQ:BuildBar()
    local wxpbar = Widget("Bar")
    local bar = wxpbar:AddChild(TEMPLATES.LargeScissorProgressBar())
    local text = wxpbar:AddChild(Text(HEADERFONT, self.fontsize_count, "100%", UICOLOURS.HIGHLIGHT_GOLD))
    text:SetPosition(0, self.fontsize_count*1.1)
    wxpbar.SetPercent = function(ui, num)
        bar:SetPercent(num)
        text:SetString("拆解总进度："..string.format("%.2f", num*100).."%")
    end
    wxpbar:SetPercent(0)
    return wxpbar
end

return SQ