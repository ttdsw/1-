local save_id, str_auto = "sw_butterfly", "自动抓蝴蝶"
local default_data = {
    time = 1,
    tool = false,
    prefabs = {"butterfly"},
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local prefab_tool = "bugnet"

local function func_left()
    local pusher = ThePlayer and ThePlayer.components.hx_pusher
    if not pusher then return end
    if pusher:GetNowTask() then
        pusher:StopNowTask()
        return
    end
    u_util:Say(str_auto, true)
    pusher:RegNowTask(function(player, pc)
        
        local fly = e_util:FindEnt(player, save_data.prefabs)
        if fly then
            
            local tool = p_util:GetItemFromAll(nil, nil, function(equip)
                return p_util:GetAction("useitem", "NET", false, equip, fly)
            end, {"equip", "mouse", "container", "backpack", "body"})
            if tool then
                if p_util:GetEquip("hands") ~= tool then
                    p_util:Equip(tool)
                else
                    p_util:TryClick(fly, "NET")
                    d_util:Wait(.7)
                end
            elseif save_data.tool and p_util:CanBuild(prefab_tool)  then
                u_util:Say(str_auto, "制作捕虫网")
                if d_util:MakeItem(prefab_tool) then
                    return u_util:Say(str_auto, "制作捕虫网失败")
                end
            else
                u_util:Say(str_auto, "缺少捕虫网", nil, nil, true)
                return true
            end
        end
        d_util:Wait()
    end, function()
        u_util:Say(str_auto, false)
    end)
end

local fn_show, fn_text = r_util:InitPack(save_data, fn_get, fn_save, func_left, "tostart_key")
local screen_data = {{
        id = "tostart_key",
        label = "辅助按键：",
        hover = "【自动抓蝴蝶】的额外绑定按键\n也可鼠标左键点击面板按钮启动",
        type = "textbtn",
        default = fn_show,
        fn = fn_text("tostart_key", str_auto),
    },
    {
        id = "tool",
        label = "捕虫网制作",
        hover = "没有捕虫网时，是否制作捕虫网",
        default = fn_get,
        fn = fn_save("tool")
    },{
        id = "list_self",
        label = "捕捉生物名单",
        hover = "名单中的生物将被自动捕捉",
        prefab = default_data.prefabs[1],
        type = "imgstr",
        fn = m_util:AddBindShowScreen{
            title = "自定义捕捉名单",
            id = "list_self",
            data = m_util:FuncListRemove(save_data, "prefabs", fn_save, function(name)
                return "捕捉："..name
            end, "你确定要自动捕捉该生物吗？", function(name, prefab)
                return "生物代码：" .. prefab .. "\n点击移除出名单！"
            end, "该生物为模组生物，无法显示图标\n点击移除出名单！"),
            fn_active = true,
            dontpop = true,
            icon = {{
                id = "add",
                prefab = "mods",
                hover = "点击添加要自动捕捉的生物",
                fn = m_util:FuncListAdd(save_data, fn_save, "prefabs", "自动捕捉", "生物"),
            },{
                id = "reset_repair",
                prefab = "revert2",
                hover = "点击重置要自动捕捉的生物清单",
                fn = m_util:FuncListReset(save_data, default_data, fn_save, "你确定要重置自动捕捉的生物清单吗？", "prefabs"),
            }}
    },}
}

local func_right = m_util:AddBindShowScreen({
    id = save_id,
    title = str_auto,
    data = screen_data,
    icon = {},
})
m_util:AddBindConf(save_id, func_left, nil, {str_auto, "butterfly" , STRINGS.LMB .. '启动/结束 ' .. STRINGS.RMB .. '高级设置'
, true, func_left, func_right, -5001}, modname)