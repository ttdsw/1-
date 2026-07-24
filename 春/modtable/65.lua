local save_id, stat_name, boss_str = "huxi_clock", "clock_time", "当前时间"
local default_data = {
    sw = m_util:IsHuxi(),
    format = "%H:%M",
    color = "珊瑚色"
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local v_data = require "data/valuetable"

local function GetOSTime()
    return os.date(save_data.format)
end

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegStat(stat_name, boss_str, "时钟设置", function()
        return save_data.sw
    end, fn_save("sw"), {
        periodic = function(data)
            data.text = GetOSTime()
            return {
                text = {
                    text = data.text,
                    color = h_util:GetRGB(save_data.color)
                }
            }
        end,
        fn_left = function(data)
            u_util:Say(STRINGS.LMB .. os.date("今天是 %Y年%m月%d日, 当前时间 %H:%M:%S "), nil, "net", nil,
                true)
        end
    }, {
        screen_data = {{
            id = "format",
            label = "时间格式：",
            fn = fn_save("format"),
            hover = "选择显示的时间格式",
            default = fn_get,
            type = "radio",
            data = {{
                data = "%H:%M:%S",
                description = "时:分:秒"
            }, {
                data = "%H:%M",
                description = "时:分"
            }}
        }, {
            id = "color",
            label = "字体颜色：",
            fn = fn_save("color"),
            hover = "选择显示的字体颜色",
            default = fn_get,
            type = "radio",
            data = v_data.RGB_datatable
        }},
        priority = -3
    })

    local default_data = {
        describe = "当前时间",
        text = GetOSTime(),
        color = h_util:GetRGB(save_data.color)
    }
    default_data.xml, default_data.tex = h_util:GetPrefabAsset("icon_shadowaligned")
    saver:AddStat(stat_name, "time", default_data)
end)
