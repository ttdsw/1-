local default_data = {
    prefabs = {"flower"}
}
local save_id, str_show = "sw_test", "开发者测试"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function fn_left()
    local pusher = m_util:GetPusher()
    if pusher then
        if pusher:GetNowTask() then
            return pusher:StopNowTask()
        else
            pusher:RegNowTask(function(player, pc)
                local sgmoving = player.sg and player.sg:HasStateTag("moving")
                local sgdoing= player.sg and player.sg:HasStateTag("doing")
                local sgworking = player.sg and player.sg:HasStateTag("working")
                local sgidle = player.sg and player.sg:HasStateTag("idle")
                local moving = player:HasTag("moving")
                local doing = player:HasTag("doing")
                local working = player:HasTag("working")
                local idle = player:HasTag("idle")
                print(os.date("%I:%M:%S %p", os.time()), idle, moving, working, doing, sgidle, sgmoving, sgworking, sgdoing)
                d_util:Wait(0.5)
            end, nil, "null")
        end
    end
end


local fn_right = function()
    local screen = require "screens/huxi/writescreen"
    TheFrontEnd:PushScreen(screen("在这里输入代码:", {text = "打印结果", cb = function(prefab)
        m_util:print(prefab)
    end}))
end

m_util:AddBindIcon(str_show, "snowman", STRINGS.LMB .. '快捷开关' .. STRINGS.RMB .. '高级设置', true, fn_left,
    fn_right, 9990)


