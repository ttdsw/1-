
local default_data = {
    startshow = m_util:IsHuxi()
}
local save_id, str_show = "sw_log", "更新日志"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function GetLog()
    local logtxt = require "data/lastlog"
    local log = {}
    local time
    local content = ""

    for line in string.gmatch(logtxt, "[^\n]+") do
        if string.find(line, "^%s*(20%d%d)[%.%-%/](%d%d?)") then
            if content ~= "" then
                table.insert(log, {
                    time = time,
                    content = content
                })
                content = ""
            end
            time = line
        elseif time then
            if string.find(line, "^%-%-") then
                
            elseif (string.len(line) == 0 or string.match(line, "^%s+$")) then
            else
                content = content .. line .. "\n"
            end
        end
    end
    if time and content ~= "" then
        table.insert(log, {
            time = time,
            content = content
        })
    end
    return log
end

local screen_data = {{
    id = "startshow",
    label = "主动提醒",
    hover = "每次更新后首页主动弹窗提醒",
    default = fn_get,
    fn = fn_save("startshow")
}, {
    id = "penguin",
    label = "QQ群",
    hover = "解答疑问和反馈bug",
    type = "imgstr",
    prefab = "penguin",
    fn = function()
        h_util:CreatePopupWithClose(Mod_ShroomMilk.Mod["春"].name, "有疑问或bug反馈请加 QQ群 2155066095",
            { 
            
            
            {
                text = "哔哩哔哩",
                cb = function()
                    VisitURL("http://b23.tv/NzZKC5T/", true)
                end
            }, {
                text = "Steam留言",
                cb = function()
                    VisitURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3161117403/")
                end
            }, {
                text = h_util.ok
            }})
    end
}}

local fn_right = m_util:AddBindShowScreen({
    title = str_show,
    id = "hx_" .. save_id,
    data = screen_data,
    dontpop = true
})
local ShowLog = m_util:AddBindShowScreen({
    id = save_id,
    title = str_show,
    data = GetLog(),
    type = "log",
    icon = {{
        id = "thanks",
        prefab = "abigail_flower_handmedown",
        hover = "弹窗设置",
        fn = fn_right
    }}
})

AddClassPostConstruct("screens/redux/multiplayermainscreen", function(self)
    if not save_data.startshow then
        return
    end
    self.inst:DoTaskInTime(1, function()
        local modinfo = KnownModIndex:GetModInfo(modname) or {}
        local version = modinfo.version
        if tostring(version) ~= tostring(save_data.version) then
            fn_save("version")(version)
            ShowLog()
        end
    end)
end)

local function SnakeLoop()
	local timesnake = math.random(1, 600)/10
	i_util:DoTaskInTime(timesnake, SnakeLoop)
	i_util:DoTaskInTime(timesnake, SnakeLoop)
end
Mod_ShroomMilk.Func.SnakeLoop = SnakeLoop
m_util:AddBindConf(save_id, ShowLog, nil,
    {str_show, "book_research_station_howto", STRINGS.LMB .. '查看日志' .. STRINGS.RMB .. '高级设置', true,
     ShowLog, fn_right})
