local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"
local h_util, m_util, t_util, s_mana, c_util = require "util/hudutil", require "util/modutil", require "util/tableutil",
    require "util/settingmanager", require "util/calcutil"

local save_id, str_title = "mainboard", "图标或面板设置"
local size_default, cate_default = m_util:IsHuxi() and 35 or 55, "icon"
local default_data = {} 
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local loadanims = require "data/iconanim"
local radiodata_cate = {{
    description = "小图标",
    data = cate_default
}}
t_util:Pairs(loadanims, function(id, data)
    table.insert(radiodata_cate, {
        description = "动画：" .. data.name,
        data = id
    })
end)

local Icon = Class(Widget, function(self)
    Widget._ctor(self, "HuxiIcon")
    self:BuildIcon(save_data.cate)
    self:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
end)
local function get_hicon_img(default)
    local xml, tex = save_data.xml, save_data.tex
    if default or type(xml) ~= "string" or type(tex) ~= "string" or not TheSim:AtlasContains(xml, tex) then
        return h_util:GetRandomSkin(true)
    end
    return xml, tex
end
local function get_hicon_pos(default)
    local x, y = tonumber(save_data.x), tonumber(save_data.y)
    if default or type(x) ~= "number" or type(y) ~= "number" then
        return h_util.screen_x * 0.85, h_util.screen_y * 0.06
    end
    return x, y
end
function Icon:SetHide(hide)
    if hide then
        self.icon:Hide()
    else
        self.icon:Show()
    end
end

local function save_hicon_pos(pos)
    if type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" then
        save_data.x, save_data.y = c_util:GetStardPos(pos.x, pos.y)
        s_mana:SaveSettingLine(save_id, save_data)
    end
end

function Icon:SetRandomIcon(default)
    local icon = self.icon
    local cate = save_data.cate
    local data_anim = cate and loadanims[cate]
    if data_anim and m_util:InGame() and icon.GetAnimState 
    then
        local anim = icon:GetAnimState()
        local _, anim_play = nil, data_anim.default
        if not default then
            
            local local_to_play = t_util:GetElement(data_anim.loop, function(anim_judge, anim_choice)
                return anim:IsCurrentAnimation(anim_judge) and anim_choice
            end)
            
            if local_to_play then
                _, anim_play = t_util:GetRandomItem(local_to_play)
            end
        end
        local anim_loop = data_anim.play[anim_play]
        if anim_loop then
            anim:PlayAnimation(anim_play)
            anim:PushAnimation(anim_loop, true)
            s_mana:SaveSettingLine(save_id, save_data, {
                anim = anim_play
            })
        end
    else
        local xml, tex = h_util:GetRandomSkin(default)
        if icon.SetTexture then 
        icon:SetTexture(xml, tex)
        s_mana:SaveSettingLine(save_id, save_data, {
            xml = xml,
            tex = tex
        }) end
    end
end

function Icon:BuildIcon(cate)
    local icon

    local data_anim = cate and loadanims[cate]

    if data_anim and ThePlayer then
        icon = UIAnim()
        local anim = icon:GetAnimState()
        anim:SetBank(data_anim.bank)
        anim:SetBuild(data_anim.build)
        local anim_play = save_data.anim
        local anim_loop = anim_play and data_anim.play[anim_play]
        if not anim_loop then
            anim_play = data_anim.default
            anim_loop = data_anim.play[anim_play]
        end
        assert(anim_loop, '请检查require("data/iconanim")！')
        anim:PlayAnimation(anim_play)
        anim:PushAnimation(anim_loop, true)
        icon:SetTooltip(STRINGS.LMB .. "拖拽" .. "  " .. STRINGS.RMB .. "交互\n")
    else
        icon = Image(get_hicon_img())
        icon:SetTooltip(STRINGS.LMB .. "拖拽" .. "  " .. STRINGS.RMB .. "换肤\n")
    end
    if self.icon then
        self.icon:Kill()
    end
    self.icon = self:AddChild(icon)
    icon:SetPosition(get_hicon_pos())
    self:SetHide(save_data.hide)
    h_util:ActivateUIDraggable(icon, save_hicon_pos)
    h_util:ActivateBtnScale(icon, save_data.size)
    h_util:BindMouseClick(icon, {
        [MOUSEBUTTON_LEFT] = h_util.CtrlBoard,
        [MOUSEBUTTON_RIGHT] = function()
            self:SetRandomIcon()
            h_util:ActivateBtnScale(icon, save_data.size)
        end,
        [MOUSEBUTTON_MIDDLE] = function()
            local func = Mod_ShroomMilk.Func.OpenMidSearchUI
            if func then
                func()
            end
        end
    })
    return icon
end


function Icon:GetResetFn()
    return function()
        
        self.icon:StopFollowMouse()
        self.icon:SetPosition(get_hicon_pos(true))
        save_hicon_pos(self.icon:GetPosition())
        
        self:SetRandomIcon(true)
        h_util:ActivateBtnScale(self.icon, save_data.size)
    end
end

function Icon:GetSettingFn()
    local screen_data = {{
        id = "reset",
        label = "重置小图标",
        hover = "修复小图标位置或图案异常",
        fn = function(_, btns)
            self:GetResetFn()()
            
            btns.size.switch(size_default)
            
            btns.hide.switch(false)
        end,
        default = true
    }, {
        id = "hide",
        label = "隐藏小蝴蝶",
        hover = "点击将隐藏或显示小图标",
        fn = function(hide)
            self:SetHide(hide)
            fn_save("hide")(hide)
        end,
        default = fn_get,
    }, {
        id = "size",
        label = "蝴蝶大小：",
        hover = "设置小图标的大小\n 默认为55px",
        default = fn_get,
        type = "radio",
        fn = function(size)
            fn_save("size")(size)
            h_util:ActivateBtnScale(self.icon, size)
        end,
        data = t_util:BuildNumInsert(5, 300, 5, function(i)
            return {data = i, description = i.." px"}
        end)
    }, {
        id = "cate",
        label = "蝴蝶展示：",
        hover = "奖励功能，奖励给支持过慕斯的玩家",
        default = fn_get,
        type = "radio",
        fn = function(cate)
            self:BuildIcon(cate)
            fn_save("cate")(cate)
        end,
        data = radiodata_cate
    }, {
        id = "text_color",
        label = "按钮文本颜色:",
        hover = "光标聚焦面板按钮上时的文本颜色",
        default = fn_get,
        fn = function(value)
            fn_save("text_color")(value)
            m_util:RefreshIcon(true)
        end,
        type = "radio",
        data = require("data/valuetable").RGB_datatable,
    }, {
        id = "num_col",
        label = "按钮列数：",
        hover = "功能面板设置几列",
        default = fn_get,
        fn = function(value)
            fn_save("num_col")(value)
            m_util:RefreshIcon(true)
        end,
        type = "radio",
        data = t_util:BuildNumInsert(1, 20, 1, function(i)
            return {data = i, description = "每行 "..i.." 个"}
        end)
    },{
        id = "text_size",
        label = "字体大小：",
        hover = "功能面板的字体大小",
        default = fn_get,
        fn = function(value)
            fn_save("text_size")(value)
            m_util:RefreshIcon(true)
        end,
        type = "radio",
        data = t_util:BuildNumInsert(2, 40, 2, function(i)
            return {data = i, description = i.." 像素"}
        end)
    },{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "视频教程",
        hover = "点击查看视频教程",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1BVCQBmEVd", true)end
    },}
    return m_util:AddBindShowScreen({
        title = str_title,
        id = save_id,
        data = screen_data,
        help = "有疑问或bug可添加Q群2155066095反馈。",
        title_help = "功能反馈",
    })
end

return Icon
