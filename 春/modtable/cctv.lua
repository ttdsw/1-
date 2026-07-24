local icons = m_util:GetIcons()
if not icons["滤镜渲染"] then return end
local xml = "images/hx_cctv.xml"
table.insert(Assets,Asset("ATLAS", xml))
local save_id, str_auto = "sw_cctv", "4K电影画质"
local default_data = {
    sw = false,
    init = true,
    drag = false,
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local function fn_ui_stop()
    if h_util:IsValid(h_util:GetHUD().cctv) then
        h_util:GetHUD().cctv:Kill()
    end
end

local function fn_ui()
    local hud = h_util:GetHUD()
    if not hud.controls then
        return
    end
    if save_data.sw then
        if not h_util:IsValid(hud.cctv) then
            hud.cctv = hud:AddChild(Widget("cctv"))
            local cctv = hud.cctv
            cctv:SetScaleMode(SCALEMODE_PROPORTIONAL)
            cctv.lb = cctv:AddChild(Image(xml, "cctv_lb.tex"))
            cctv.lb:SetPosition(save_data.x1 or 155, save_data.y1 or 655)
            cctv.lb:SetScale(.55)
            cctv.ru = cctv:AddChild(Image(xml, "cctv_ru.tex"))
            cctv.ru:SetPosition(save_data.x2 or 155, save_data.y2 or 100)
            cctv.ru:SetScale(.55)
            cctv.rr = cctv:AddChild(Widget("cctv_rr"))
            local rr = cctv.rr
            rr:SetPosition(save_data.x3 or 1154, save_data.y3 or 105)
            cctv.lu = rr:AddChild(Image(xml, "cctv_lu.tex"))
            cctv.lu:SetScale(.33)
            cctv.txt = rr:AddChild(Image(xml, "cctv_txt.tex"))
            cctv.txt:SetPosition(0, 232)
            cctv.txt:SetScale(.8)
            if save_data.drag then
                local function fn_pos(x, y)
                    return function(pos)
                        s_mana:SaveSettingLine(save_id, save_data, {[x] = pos.x, [y] = pos.y})
                    end
                end
                h_util:ActivateUIDraggable(cctv.lb, fn_pos("x1", "y1"))
                h_util:ActivateUIDraggable(cctv.ru, fn_pos("x2", "y2"))
                h_util:ActivateUIDraggable(cctv.rr, fn_pos("x3", "y3"))
            else
                cctv:SetClickable(false)
            end
        end
    else
        fn_ui_stop()
    end
end

i_util:AddPlayerActivatedFunc(fn_ui)


local function fn_fresh()
    fn_save()
    fn_ui_stop()
    fn_ui()
end
local function fn_left()
    if save_data.sw then
        fn_save("sw")(false)
        h_util:CreatePopupWithClose(str_auto, "已关闭，哈哈，愚人节快乐！")
    elseif save_data.init then
        h_util:CreatePopupWithClose(str_auto, "你确定要启用4K画质吗？\n", {
            {text = "取消"},
            {text = "确认启用！", cb = function()
                save_data.sw = true
                save_data.init = false
                fn_save()
            end}
        })
    else
        fn_save("sw")(true)
        h_util:CreatePopupWithClose(str_auto, "启用成功！请尽情享受电影画质！")
    end
    fn_ui()
end


local screen_data = {
    {
        id = "reset",
        label = "重置位置",
        hover = "重置UI位置",
        default = true,
        fn = function()
            save_data.x1 = nil
            save_data.y1 = nil
            save_data.x2 = nil
            save_data.y2 = nil
            save_data.x3 = nil
            save_data.y3 = nil
            fn_fresh()
            h_util:PlaySound("learn_map")
        end,
    },{
        id = "drag",
        label = "允许拖拽UI",
        hover = "是否允许拖拽UI",
        default = fn_get,
        fn = function(value)
            save_data.drag = value
            fn_fresh()
        end,
    },
}

m_util:AddBindIcon(str_auto, {xml = xml, tex = "logo.tex"}, STRINGS.LMB .. '启用/禁用' .. STRINGS.RMB .. '高级设置', true, fn_left, m_util:AddBindShowScreen{
    id = save_id,
    title = str_auto,
    data = screen_data,
}, 9995)