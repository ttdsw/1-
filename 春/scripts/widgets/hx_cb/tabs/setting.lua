local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local f_util = require "util/fn_hxcb"
local save_data = f_util.save_data
local g_util = require "util/fn_gallery"

local c_util, e_util, h_util, m_util, t_util, p_util = require "util/calcutil", require "util/entutil",
    require "util/hudutil", require "util/modutil", require "util/tableutil", require "util/playerutil"

local opt_enable = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
local auth_enable = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = "授权", data = true } }
local LMB, RMB = STRINGS.LMB, STRINGS.RMB
local function UI_Reset()
    local ui = h_util:GetCB()
    if ui then
        ui:BuildUI()
    end
end
local scale_table = t_util:BuildNumInsert(.1, 2, .05, function(i)
    return {data = i, text = string.format("%.2f 倍率", i)}
end)
local hxcb_settings = {
    {
        id = "lright",
        label = "页面布局：",
        data = {{ text = "左对齐", data = false }, { text = "右对齐", data = true }},
        hover = "搜索网格靠左还是靠右\n右对齐更接近老版本的 T键控制台",
        type = "radio",
        fn = UI_Reset,
    },
    {
        id = "tip_pos",
        label = "提示信息：",
        data = { { text = "远程，他人可见", data = "whisper" },  { text = "远程，附近可见", data = "mine" }, { text = "简易，自己可见", data = "only" }, { text = "聊天，自己可见", data = "self" }, { text = "通告, 全服可见", data = "ann"}, { text = STRINGS.UI.OPTIONS.DISABLED, data = "shutup"}},
        hover = "【简易/远程】模式下玩家头上生成提示信息，【通告】会发送系统公告\n推荐设置成【远程，他人可见】，这样就和旧版T键控制台一样了",
        type = "radio",
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    },{
        id = "code_hover",
        label = "浮动代码：",
        data = opt_enable,
        hover = "鼠标悬停在网格上时，是否显示代码",
        type = "radio",
    },{
        id = "ui_waves",
        label = "底部小旗：",
        data = opt_enable,
        hover = "控制台页面底部是否增加额外的小旗按钮，\n用来快速保存或重载游戏",
        type = "radio",
    },
    {
        id = "pop_ensure",
        label = "指令确认：",
        data = opt_enable,
        hover = "部分危险指令是否需要二次确认\n比如杀死玩家，清空物品，重启游戏等",
        type = "radio",
    },
    {
        id = "spawn_ensure",
        label = "生成确认：",
        data = opt_enable,
        hover = "生成实体的网格需要绿标选中\n这样方便通过底部扩展单元生成物品",
        type = "radio",
    },
    {
        id = "spawn_anchor",
        label = "手指对齐：",
        data = opt_enable,
        hover = "使用右键菜单的【金手指】或者【银手指】功能时，\n是否自动对齐到几何网格",
        type = "radio",
    },
    {
        id = "skin_enable",
        label = "皮肤模式：",
        data = opt_enable,
        hover = "是否生成带皮肤的物品\n注意：该皮肤为玩家上次制作物品时自带的皮肤，并不能给予你尚未拥有的皮肤(?",
        type = "radio",
    },
    {
        id = "midbind",
        label = "快捷中键：",
        data = {
            {data = "R_SpawnMany", text = "批量生成"},
            {data = "R_FindNext", text = "立即传送"},
            {data = "R_GetRecipe", text = "获取材料"},
            {data = "R_AddRecipe", text = "解锁原型"},
            {data = "R_SpawnRunning", text = "金手指"},
            {data = "R_CountPrefab", text = "宣告数量"},
            
        },
        hover = "鼠标中键"..(h_util:GetStringKeyBoardMouse(MOUSEBUTTON_MIDDLE) or "").."点击时，直接触发的功能",
        type = "radio",
    },
    {
        id = "equipmem",
        label = "装备记忆：",
        data = opt_enable,
        hover = "玩家穿上不在【装备】标签的物品时，会自动保存到【装备】标签中",
        type = "radio",
        reset = true,
    },
    {
        id = "modfilter",
        label = "模组过滤：",
        data = opt_enable,
        hover = "【模组】标签下是否仅展示服务器模组的物品",
        type = "radio",
        fn = function()
            g_util.prefabs.mod = nil
            package.loaded["data/hx_cb/cates/mod"] = nil
        end
    },{
        id = "num_spawn",
        label = "批量生成：",
        hover = "右键扩展菜单或者中键快捷生成时，单次生成物品的数量\n"..LMB.."自定义 "..RMB.."恢复默认",
        type = "numbtn",
        fnstr = function(str)
            return "一次 "..str.." 个"
        end,
        title = "请设置右键菜单中生成物品数量：",
        default = 10,
    },{
        id = "range_delete",
        label = "删除半径：",
        hover = "控制台-物品或生物-附近-删除 功能的清理范围，每 4 格墙点的距离为一块地皮的长度\n"..LMB.."自定义 "..RMB.."恢复默认",
        type = "numbtn",
        fnstr = function(str)
            return str.." 墙点"
        end,
        title = "请设置【附近-删除】功能的扫描半径：",
        default = 3,
    },{
        id = "range_kill",
        label = "击杀半径：",
        hover = "控制台-物品或生物-附近-击杀 功能的生效范围，每 4 格墙点的距离为一块地皮的长度\n"..LMB.."自定义 "..RMB.."恢复默认",
        type = "numbtn",
        fnstr = function(str)
            return str.." 墙点"
        end,
        title = "请设置【附近-击杀】功能的扫描半径：",
        default = m_util:IsHuxi() and 64 or 20,
    }
}

if m_util:IsMilker() then
    table.insert(hxcb_settings,
        {
            id = "code_pri",
            label = "打印指令：",
            data = opt_enable,
            hover = "操作指令是否在本地控制台中打印\n按下CTRL+L就能看见向服务器发送了什么指令",
            type = "radio",
        }
    )
    table.insert(hxcb_settings,
        {
            id = "__authorize",
            label = "扩展权限：",
            data = auth_enable,
            hover = "启用此项后控制台会有更多物品和生物的分类\n但影响加载速度, 甚至崩溃！",
            type = "radio",
            reset = true,
        }
    )
end
if m_util:IsHuxi() then
    table.insert(hxcb_settings,
        {
            id = "immodder",
            label = "开发者模式：",
            data = opt_enable,
            hover = "进游戏是否自动开启如下模式：\n创造模式、上帝模式、全天日食",
            type = "radio",
        }
    )
end

local ST = Class(Widget, function(self, CB)
    Widget._ctor(self, "huxi_console_board_console")

    local data_str = {"width_bg", "height_bg", "size_font"}
    t_util:IPairs(data_str, function(str) self[str] = CB[str] end)

    self.label_width = self.width_bg/4.5
    self.radio_width = self.width_bg/3.5
    self.space_between = 5
    self.radio_height = 36
    self.radio_offset = -10

    self.itembg_width = self.label_width + self.radio_width + self.space_between + 15
    self.itembg_height = self.radio_height + self.space_between

    
    self.tool_tip = self:AddChild(self:MakeTooltip())
    self:LoadAndPaint()


end)

function ST:MakeTooltip()
    local w = Widget("tooltip")
    local text = w:AddChild(Text(CHATFONT, self.size_font+3, ""))
	text:SetHAlign(ANCHOR_LEFT)
	text:SetVAlign(ANCHOR_TOP)
	text:SetRegionSize(self.width_bg, self.height_bg)
	text:EnableWordWrap(true)
    local posy_text = -self.height_bg * 5/6
    text:SetPosition(self.size_font, posy_text)
    w.ui_text = text

    local divider = w:AddChild(Image("images/hx_ui.xml", "quagmire_recipe_line.tex"))
    divider:ScaleToSize(self.width_bg, self.size_font)
    divider:SetPosition(0, self.height_bg/2 + posy_text + self.size_font)
    w:Hide()
	return w
end

function ST:AddListItemBackground(w)
	w.bg = w:AddChild(TEMPLATES.ListItemBackground(self.itembg_width, self.itembg_height))
	w.bg:MoveToBack()
end

function ST:Paint_radio(data)
    local function fn_radio(sel, old)
        f_util.fn_save(data.id)(sel)
        if data.fn then
            data.fn(sel, old)
        end
        if data.reset then
            h_util:CreatePopupWithClose("提示", "该设置修改后，重启游戏才能完全生效。")
        end
    end
    local w = TEMPLATES.LabelSpinner(data.label, data.data, self.label_width, self.radio_width, self.radio_height, self.space_between, nil, self.size_font, self.radio_offset, fn_radio, nil, data.hover)
    self:AddListItemBackground(w)
    local default = save_data[data.id]
    local index = t_util:ForIGet(w.spinner.options, function(k, v)
        return v.data == default and k
    end)
    if index then
        w.spinner:SetSelectedIndex(index)
    end
    return w
end

function ST:Paint_numbtn(data)
    local w = Widget(data.id)
    
    local w = TEMPLATES.LabelSpinner(data.label, {}, self.label_width, self.radio_width, self.radio_height, self.space_between, nil, self.size_font, self.radio_offset, function()end, nil, data.hover)
    self:AddListItemBackground(w)
    local sp = w.spinner
    sp.leftimage:Hide()
    sp.rightimage:Hide()
    w.flush = function()
        local str = save_data[data.id] or ""
        str = data.fnstr and data.fnstr(str) or str
        sp.text:SetString(str)
    end
    w.flush()

    h_util:BindMouseClick(sp.background, {
        [MOUSEBUTTON_LEFT] = function()
            h_util:CreateWriteWithClose(data.title, {
                text = "确认",
                cb = function(str)
                    local num = tonumber(str)
                    if num and num >= 1 and num % 1 == 0 then
                        f_util.fn_save(data.id)(num)
                        w.flush()
                    else
                        h_util:CreatePopupWithClose("不行的", "要输入正整数哦。")
                    end
                end
            })
        end,
        [MOUSEBUTTON_RIGHT] = function()
            f_util.fn_save(data.id)(data.default)
            w.flush()
        end
    })
    return w
end



function ST:LoadAndPaint()
    local w = self:AddChild(Widget("items"))
    local num_tip = 0
    for i, data in ipairs(hxcb_settings) do
        local fn = self["Paint_" .. data.type]
        if fn then
            local ui = w:AddChild(fn(self, data))
            local offset_x = i % 2 == 0 and self.itembg_width + self.space_between or 0
            local offset_y = math.ceil(i/2)-1
            ui:SetPosition(offset_x, -offset_y * self.itembg_height)
            ui:SetOnGainFocus(function()
                self.tool_tip.ui_text:SetString(data.hover)
                self.tool_tip:Show()
                num_tip = num_tip + 1
            end)
            ui:SetOnLoseFocus(function()
                if num_tip <= 1 then
                    self.tool_tip:Hide()
                end
                num_tip = num_tip - 1
            end)
        end
    end

    w:SetPosition(self.width_bg * -.5 + self.itembg_width * .5 - 25, self.height_bg * .5 - self.itembg_height * .5)
    self.items = self:AddChild(w)
end


return ST