local save_id, stat_name, boss_str = "huxi_pos", "posdata", "当前坐标"
local default_data = {
    sw = false
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local v_data = require "data/valuetable"

local function GetPos()
    if ThePlayer then
        local x, _, z = ThePlayer.Transform:GetWorldPosition()
        return string.format("%.2f\n%.2f", x, z)
    else
        return "x:--.--\nz:--.--"
    end
end

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegStat(stat_name, boss_str, "坐标设置", function()
        return save_data.sw
    end, fn_save("sw"), {
        periodic = function(data)
            data.text = GetPos()
            return {
                text = {
                    text = data.text
                }
            }
        end,
        fn_left = function(data)
            local x, _, z = ThePlayer.Transform:GetWorldPosition()
            local str = "我的坐标: (" .. string.format("%.2f", x) .. " , " .. string.format("%.2f", z) .. ")"
            u_util:Say(STRINGS.LMB .. str, nil, "net", nil, true)
        end
    }, {
        priority = -2
    })

    local default_data = {
        describe = "我的坐标",
        text = GetPos(),
        color = h_util:GetRGB(save_data.color)
    }
    default_data.xml, default_data.tex = h_util:GetPrefabAsset("icon_uses")
    saver:AddStat(stat_name, "pos", default_data)
end)
