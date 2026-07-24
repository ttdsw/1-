local save_id, str_auto_read = "sw_autoread", "自动" .. STRINGS.ACTIONS.READ
local default_data = {
    sw = true,
    timetick = 0,
    stop = false,
    tip = true,
    color = "粉色",
    find = true,
    range = 64,
    keep = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local book_tags = {"bookcabinet_item", "book"}


m_util:AddRightMouseData(save_id, str_auto_read, "是否启用自动读书", function()
    return save_data.sw
end, fn_save("sw"), {
    screen_data = {{
        id = "readme",
        label = "使用指南",
        fn = function()
            h_util:CreatePopupWithClose(str_auto_read .. " · 使用指南",
                "按住CTRL点击书本可以自动阅读书籍\n（保留一次耐久）")
        end,
        hover = "点击查看教程",
        default = true
    }, {
        id = "timetick",
        label = "读书间隔：",
        fn = fn_save("timetick"),
        hover = "设置每次读书间隔",
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(0, 60, 1, function(i)
            return {
                data = i,
                description = i == 0 and "最快速度" or i .. " 秒一次"
            }
        end)
    }, {
        id = "find",
        label = "寻找书籍",
        fn = fn_save("find"),
        hover = "没有书籍可阅读时，是否去别的容器寻找书籍",
        default = fn_get
    }, {
        id = "range",
        label = "搜寻范围：",
        fn = fn_save("range"),
        hover = "寻找书籍的范围",
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(4, 64, 4, function(i)
            return {
                data = i,
                description = i .. " 墙点"
            }
        end)
    }, {
        id = "keep",
        label = "耐久保留",
        fn = fn_save("keep"),
        hover = "是否书籍保留最后一次耐久",
        default = fn_get
    }, {
        id = "stop",
        label = "无书终止",
        fn = fn_save("stop"),
        hover = "没有可用书籍时，自动终止读书。",
        default = fn_get
    }, {
        id = "tip",
        label = "文字提示",
        fn = fn_save("tip"),
        hover = "是否显示自动阅读开启提示",
        default = fn_get
    }, {
        id = "color",
        label = "提示颜色：",
        fn = fn_save("color"),
        hover = "提示文字颜色",
        default = fn_get,
        type = "radio",
        data = require("data/valuetable").RGB_datatable
    }, {
        id = "readme",
        label = "玩家留言",
        fn = function()
            h_util:CreatePopupWithClose("󰀍" .. str_auto_read .. " · 特别鸣谢󰀍",
                "请多关爱读书机器人。\n              —卡卡")
        end,
        hover = "特别鸣谢",
        default = true
    }},
    priority = 100
})


i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if e_util:IsValid(item_inv) and item_inv:HasTags(book_tags) and TheInput:IsKeyDown(KEY_CTRL) then
        if type(str) == "string" and str:rfind_plain(STRINGS.ACTIONS.READ) then
            return save_data.sw and str:gsub(STRINGS.ACTIONS.READ, str_auto_read)
        end
    end
end)

local function Say(str)
    if save_data.tip then
        u_util:Say(str_auto_read, str, nil, save_data.color, true)
    end
end

i_util:AddRightClickFunc(function(pc, player, down, act_right, ent_mouse)
    
    if down or not TheInput:IsKeyDown(KEY_CTRL) or not save_data.sw then
        return
    end
    local item = t_util:GetRecur(TheInput:GetHUDEntityUnderMouse(), "widget.parent.item")
    if not (e_util:IsValid(item) and item:HasTags(book_tags)) then
        return
    end
    local prefab = item.prefab
    local comps = e_util:ClonePrefab(prefab).components
    local total = comps.finiteuses and comps.finiteuses.total
    local pusher = player.components.hx_pusher
    if not (type(total) == "number" and pusher) then
        return
    end
    
    local min_perc = 100 / total
    Say(save_data.timetick == 0 and "启动，当前最快速度" or "启动，当前间隔 " .. save_data.timetick ..
            " 秒")

    local stations_openned = {}
    pusher:RegNowTask(function()
        local books = p_util:GetItemsFromAll(prefab, nil, function(ent)
            if save_data.keep then
                return e_util:GetPercent(ent) > min_perc
            else
                return true
            end
        end)
        table.sort(books, function(a, b)
            return e_util:GetPercent(a) > e_util:GetPercent(b)
        end)
        local book = books[1]
        if book then
            local act = p_util:GetAction("inv", "READ", true, book)
            if act then
                p_util:DoAction(act, RPC.ControllerUseItemOnSelfFromInvTile, act.action.code, book)
                local _perc = e_util:GetPercent(book)
                repeat
                    d_util:Wait()
                until (e_util:GetPercent(book) ~= _perc) or not p_util:IsInBusy()
            end
        elseif save_data.stop then
            Say("缺少可用书籍")
            return true
        elseif save_data.find then
            local stations = e_util:FindEnts(player, nil, save_data.range, {"_container", "structure"}, {"burnt"}, nil,
                nil, function(station)
                    if Mod_ShroomMilk.Func.HasPrefabWithBox then
                        return Mod_ShroomMilk.Func.HasPrefabWithBox(station, prefab, true)
                    else
                        return true
                    end
                end)
            
            local station = t_util:IGetElement(stations, function(station)
                if p_util:IsOpenContainer(station) then
                    table.insert(stations_openned, station)
                else
                    return not table.contains(stations_openned, station) and station
                end
            end)
            if station then
                repeat
                    local act, right = p_util:GetMouseActionSoft({"RUMMAGE"}, station)
                    if act then
                        p_util:DoMouseAction(act, right)
                    end
                    d_util:Wait(0.5)
                until e_util:IsValid(station) and p_util:IsOpenContainer(station)
            else
                stations_openned = {}
            end
        end
        d_util:Wait(save_data.timetick)
    end)
end)
