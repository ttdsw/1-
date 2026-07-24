local save_id, stat_name, buff_str = "huxi_nightmare", "nightmare", "暴动倒计时"
local Data = {}
local xml1, tex1 = h_util:GetPrefabAsset("nightmare_timepiece")
local xml2, tex2 = h_util:GetPrefabAsset("nightmare_timepiece_warn")
local xml3, tex3 = h_util:GetPrefabAsset("nightmare_timepiece_nightmare")
local default_data = {
    sw = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local phase_data = {
    calm = {
        xml = xml1,
        tex = tex1,
        describe = "平息",
        color = h_util:GetRGB("白色")
    },
    warn = {
        xml = xml2,
        tex = tex2,
        describe = "警告",
        color = h_util:GetRGB("黄色")
    },
    dawn = {
        xml = xml2,
        tex = tex2,
        describe = "过渡",
        color = h_util:GetRGB("粉色")
    },
    wild = {
        xml = xml3,
        tex = tex3,
        describe = "暴动",
        color = h_util:GetRGB("红色")
    },
    default = {
        describe = "未知",
        text = "--:--",
        xml = xml1,
        tex = tex1
    }
}
local ti_last = 1
local meta = {
    text = {
        text = "--:--",
        color = h_util:GetRGB("白色")
    },
    img = {
        xml = xml1,
        tex = tex1
    },
    describe = "未知"
}
i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    if not world:HasTag("cave") then
        return
    end
    saver:RegStat(stat_name, buff_str, "洞穴中的梦魇时间倒计时", function()
        return save_data.sw
    end, fn_save("sw"), {
        periodic = function(data)
            local phase, ti = Data.phase, Data.timeinphase
            local info = type(ti) == "number" and phase and phase_data[phase]
            if info then
                local info = phase_data[phase]
                
                
                local left_time = (1 - ti) / (ti - ti_last)
                data.value = left_time
                data.stat = info.describe
                if left_time > 0 then
                    meta.text.text = saver:FormatSecond(left_time)
                    meta.img.xml = info.xml
                    meta.img.tex = info.tex
                    meta.describe = info.describe
                    meta.text.color = info.color
                else
                    meta.text.text = "状态变化中"
                    meta.describe = "未知"
                end
                if ti == 1 and phase == "wild" then
                    data.stat = "暴动锁定"
                    meta = {
                        text = {
                            text = "暴动锁定"
                        },
                        img = {
                            xml = xml3,
                            tex = tex3
                        },
                        describe = "暴动锁定"
                    }
                end
                ti_last = ti
            end
            local describe
            return meta
        end,
        fn_left = function(data)
            local time = tonumber(data.value)
            local phase = data.stat
            if time and phase then
                local str_say = string.format("%s阶段 将在 %s 后结束。", phase, c_util:FormatSecond_ms(time))
                if phase == "暴动锁定" then
                    str_say = "已锁定暴动状态！准备击杀暗影编织者！"
                end
                if time < 0 then
                    str_say = "正在变换暴动状态..."
                end
                u_util:Say(STRINGS.LMB .. str_say, nil, "net", nil, true)
            end
        end
    })

    saver:AddStat(stat_name, "fuckdata", phase_data.default)
    e_util:SetBindEvent(world, "nightmareclocktick", function(world, data)
        Data = data or {}
    end)
end)
