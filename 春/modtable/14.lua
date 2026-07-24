local save_id, str_show, logo = "sw_small", "小功能绑定", "glassblock"
local default_data = {
    tommp = m_util:IsHuxi(),
    tommp_key = 110,
    exit_time = 0,
    exit_en = false
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function fn_mmp()
    local mv = not m_util:GetMovementPrediction()
    m_util:SetMovementPrediction(mv)
    u_util:Say(mv and "开启" or "关闭", mv and "延迟补偿已开启" or "延迟补偿已关闭", nil,
        mv and "春绿色" or "红色", true)
end
local function fn_back()
    DoRestart(true)
end
local function fn_exit()
    
    local time = os.time()
    if type(time) == "number" then
        save_data.exit_time = time
        save_data.exit_en = true
        fn_save()
        DoRestart(true)
    end
end
AddClassPostConstruct("screens/redux/networkloginpopup", function(self)
    if save_data.exit_en then
        local time = os.time()
        if type(time) == "number" and type(save_data.exit_time) == "number" then
            if save_data.exit_time - time < 120 then
                fn_save("exit_en")(false)
                RequestShutdown()
            end
        end
    end
end)

local datatable = {{
    id = "tommp",
    fn = fn_mmp,
    name = "切换延迟补偿",
    hover = "一键切换延迟补偿"
}, {
    id = "toback",
    fn = fn_back,
    name = "退出到主页",
    hover = "一键断开连线，并回到主页"
}, {
    id = "toexit",
    fn = fn_exit,
    name = "退出到桌面",
    hover = "一键断开连接，然后到游戏主页，再退出到桌面"
}}

local function fn_refresh(player)
    t_util:IPairs(datatable, function(data)
        r_util:BindKeyFunc(data.fn)
    end)
    t_util:IPairs(datatable, function(data)
        r_util:BindKeyFunc(data.fn, save_data[data.id] and save_data[data.id .. "_key"])
    end)
end
i_util:AddSessionLoadFunc(function()
    
    fn_refresh()
end)
local function fn_set(id)
    return function(val)
        fn_save(id)(val)
        fn_refresh(ThePlayer)
    end
end
local fn_show = r_util:GetLabelShow(fn_get)
local fn_text = r_util:GetLabelSet(fn_set)

local screen_data = {}
t_util:IPairs(datatable, function(data)
    local ID, NAME = data.id, data.name
    local KEY = ID .. "_key"
    table.insert(screen_data, {
        id = ID,
        label = NAME,
        hover = data.hover,
        default = fn_get,
        fn = fn_set(ID)
    })
    table.insert(screen_data, {
        id = KEY,
        label = "快捷键：",
        hover = subfmt("【{name}】的绑定按键", {
            name = NAME
        }),
        type = "textbtn",
        default = fn_show,
        fn = fn_text(KEY, NAME)
    })
end)
m_util:AddBindShowScreen(save_id, str_show, logo, "多个小功能的按键绑定设置", {
    title = str_show,
    id = save_id,
    data = screen_data
})
