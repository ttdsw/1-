
local default_data = {
    prefabs = {"flower_evil"}
}
local save_id, str_show, img_show = "sw_space", "空格过滤器", "stagehand"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= ThePlayer then
        return
    end
    local _GetActionButtonAction = self.GetActionButtonAction
    self.GetActionButtonAction = function(self, ...)
        local act = _GetActionButtonAction(self, ...)
        if act and table.contains(save_data.prefabs, act.target and act.target.prefab) then
            return
        end
        return act
    end
end)

local function fn_showdata()
    return t_util:IPairToIPair(save_data.prefabs, function(prefab)
        local name = e_util:GetPrefabName(prefab)
        local label = name == e_util.NullName and prefab or name
        local data = {}
        if h_util:GetPrefabAsset(prefab) then
            data.type = "imgstr"
            data.prefab = prefab
            data.label = label
        else
            data.type = "textbtn"
            data.label = "未知物品："
            data.default = label
        end
        return t_util:MergeMap({
            id = prefab,
            hover = "物品代码：" .. prefab .. "\n点击移除该物品的过滤！",
            fn = function()
                h_util:CreatePopupWithClose(str_show, "你确定要移除对 " .. label .. " 的过滤吗？", {{
                    text = h_util.no
                }, {
                    text = h_util.yes,
                    cb = function()
                        t_util:Sub(save_data.prefabs, prefab)
                        fn_save()
                    end
                }})
            end
        }, data)
    end)
end

local fn_screenadd = function()
    
    m_util:PushPrefabScreen{
        text_title = "选择要过滤的物品",
        text_btnok = "添加过滤",
        hover_btnok = "添加该物品到过滤列表",
        fn_btnok = function(prefab)
            t_util:Add(save_data.prefabs, prefab, true)
            fn_save()
        end
    }
end

local icondata = {{
    id = "add",
    prefab = "mods",
    hover = "点击添加要空格过滤的物品！",
    fn = fn_screenadd
}}

local fn_left = m_util:AddBindShowScreen{
    title = str_show,
    id = "hx_" .. save_id,
    data = fn_showdata,
    icon = icondata,
    help = '这里展示的物品不会被 空格 响应，但响应鼠标点击的动作。\n点击右侧扳手按钮可添加过滤，点击下方物品名移除过滤。',
    fn_active = true
}
m_util:AddBindConf(save_id, fn_left, nil, {str_show, img_show, STRINGS.LMB .. str_show .. '设置', true, fn_left})
