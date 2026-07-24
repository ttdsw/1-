local save_id, map_str = "sw_map", "地图图标"
local default_data = {
    sw = true,
    icon_size = 15,
    map_show = true,
    hud_show = true,
    hud_mouse = m_util:IsHuxi(),
    map_mouse = m_util:IsHuxi(),
    btn_conf = 1002
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local Hmap = require "widgets/huxi/huxi_map"
i_util:AddPlayerActivatedFunc(function(player, world, pusher, saver)
    local hud = player.HUD
    if hud.hx_map then
        hud.hx_map:Kill()
    end
    hud.hx_map = hud:AddChild(Hmap(hud))
    hud.hx_map:BuildHMap(save_data, saver:GetHMapUIData())
    saver:SetHMapConf(save_data, fn_save)
end)

local function fn_set(conf)
    return function(value)
        fn_save(conf)(value)
        local saver = m_util:GetSaver()
        if saver then
            saver:RefreshHMap()
        end
    end
end
AddClassPostConstruct("widgets/mapcontrols", function(self)
    local _OnMouseButton = self.OnMouseButton
    function self.OnMouseButton(self, btn, down, ...)
        if self.focus and down and btn == save_data.btn_conf then
            if save_data.hud_mouse then
                fn_set("hud_show")(not save_data.hud_show)
            end
            
            if save_data.map_mouse then
                fn_set("map_show")(not save_data.map_show)
            end
        end
        return _OnMouseButton(self, btn, down, ...)
    end
end)
AddClassPostConstruct("screens/mapscreen", function(self)
    if self.hx_map then
        self.hx_map:Kill()
    end
    self.hx_map = self:AddChild(Hmap(self))
    local saver = m_util:GetSaver()
    if saver then
        self.hx_map:BuildHMap(save_data, saver:GetHMapUIData())
    end

    
    
    
    
    
    
    
    
    
    
    
end)

local function GetScreenData()
    local screen_data = {
        title = "超级强大的 " .. map_str,
        id = save_id,
        data = {}
    }
    local ui_data = screen_data.data
    local saver = m_util:GetSaver()
    if not saver then
        return screen_data
    end
    local data_ss = saver:GetHMapShowScreenData()
    t_util:IPairs(data_ss, function(data)
        table.insert(ui_data, {
            id = data.id,
            label = data.label,
            hover = data.hover,
            default = data.default,
            fn = function(value)
                if type(data.fn) == "function" then
                    data.fn(value)
                end
                
                saver:SetHMapSW(data.id, value)
            end
        })
        if data.screen_data then
            table.insert(ui_data, {
                id = data.id .. "_setting",
                label = "高级设置：",
                hover = "点击进入" .. data.label .. "的高级设置",
                default = data.label,
                type = "textbtn",
                fn = function()
                    m_util:PopShowScreen()
                    m_util:AddBindShowScreen{
                        title = data.label .. " 高级设置",
                        id = data.id .. "_showscreen",
                        data = type(data.screen_data) == "function" and data.screen_data() or data.screen_data
                    }()
                end
            })
        end
    end)
    screen_data.data = t_util:MergeList(ui_data, {{
        id = "map_show",
        label = "总开关：地图图标显示",
        fn = fn_set("map_show"),
        hover = "开启地图后\n是否显示图标",
        default = fn_get
    }, {
        id = "map_mouse",
        label = "图标地图快切",
        fn = fn_set("map_mouse"),
        hover = "点击【地图按钮】开关图标显示",
        default = fn_get
    }, {
        id = "hud_show",
        label = "总开关：鹰眼图标显示",
        fn = fn_set("hud_show"),
        hover = "开启鹰眼后\n是否显示图标",
        default = fn_get
    }, {
        id = "hud_mouse",
        label = "图标鹰眼快切",
        fn = fn_set("hud_mouse"),
        hover = "点击【地图按钮】开关图标显示",
        default = fn_get
    }, {
        id = "btn_conf",
        label = "快切绑定：",
        fn = fn_save("btn_conf"),
        hover = "设置快切绑定按键",
        default = fn_get,
        type = "radio",
        data = h_util:SetMouseSecond()
    }, {
        id = "icon_size",
        label = "所有图标大小：",
        fn = fn_set("icon_size"),
        hover = "每个图标的缩放大小",
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(1, 50, 1, function(i)
            return {
                data = i,
                description = i .. " 像素"
            }
        end)
    }})
    return screen_data
end

m_util:AddBindShowScreen(save_id, map_str, "stash_map", "各种地图图标相关设置", function()
    m_util:AddBindShowScreen(GetScreenData())()
end, nil, 9998)
