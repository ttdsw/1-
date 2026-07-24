local w_util = require "util/worldutil"
local default_data = {
    sw = true
}
local save_id, str_show = "map_preview", "地形预览"
local l_data = require "data/layouttable"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local img_show = "cartographydesk"
local flag_scanned
local node_data = {}


local function AddNode(pos, icon)
    if node_data[icon] then
        table.insert(node_data[icon], pos)
    else
        node_data[icon] = {pos}
    end
end

local function fn_get_node()
    if flag_scanned or not w_util:Enable() then
        return node_data
    end
    flag_scanned = true
    local l_node = TheWorld:HasTag("cave") and l_data.node.cave or l_data.node.forest
    local m_room, m_id, m_node = w_util:GetWorldNodes()
    t_util:IPairs(l_node, function(lta)
        if lta.room then
            local rooms = type(lta.room) == "table" and lta.room or {lta.room}
            t_util:IPairs(rooms, function(room)
                t_util:IPairs(m_room[room] or {}, function(pos)
                    AddNode({
                        x = pos.x,
                        z = pos.z
                    }, lta.icon)
                end)
            end)
        elseif lta.all then
            local alls = type(lta.all) == "table" and lta.all or {lta.all}
            t_util:IPairs(alls, function(all)
                t_util:Pairs(m_id, function(i, all_name)
                    if all_name:rfind_plain(all) then
                        local node_data = m_node[i]
                        AddNode({
                            x = node_data.x,
                            z = node_data.y
                        }, lta.icon)
                    end
                end)
            end)
        elseif lta.task then
            local tasks = type(lta.task) == "table" and lta.task or {lta.task}
            t_util:IPairs(tasks, function(task)
                local pos_list = t_util:PairToIPair(m_id, function(id, task_name)
                    return task_name:rfind_plain(task) and m_node[id]
                end)
                local pos
                t_util:IPairs(pos_list, function(_pos)
                    if pos then
                        pos.x = (_pos.x + pos.x) / 2
                        pos.y = (_pos.y + pos.y) / 2
                    else
                        pos = t_util:MergeMap(_pos)
                    end
                end)
                if pos then
                    AddNode({
                        x = pos.x,
                        z = pos.y
                    }, lta.icon)
                end
            end)
        end
    end)
    return node_data
end

local function PackScreenData()
    local func_get_all = Mod_ShroomMilk.Func.GetAllScanIcons
    local icon_map = func_get_all and func_get_all() or fn_get_node()
    local icon_list = t_util:PairToIPair(icon_map, function(icon, pos_list)
        return {
            icon = icon,
            pos_list = pos_list
        }
    end)
    local order_map = t_util:PairToPair(l_data.order, function(i, icon)
        return icon, 100 - i
    end)
    table.sort(icon_list, function(a, b)
        local oa, ob = order_map[a.icon] or 0, order_map[b.icon] or 0
        return oa > ob
    end)
    return t_util:IPairToIPair(icon_list, function(data)
        local count = #data.pos_list
        local icon = data.icon
        local name = l_data.chs[icon] or e_util:GetPrefabName(icon)
        return {
            id = icon,
            label = count .. " 处 " .. name,
            hover = STRINGS.LMB .. (ThePlayer and " 点击跳转" or " 点击宣告"),
            type = "imgstr",
            prefab = icon,
            fn = function()
                if ThePlayer then
                    local saver = m_util:GetSaver()
                    if saver and save_data.sw then
                        t_util:IPairs(data.pos_list, function(pos)
                            saver:AddHMap(save_id, {
                                x = pos.x,
                                z = pos.z,
                                icon = icon
                            }, true)
                        end)
                        local ctrl = h_util:GetControls()
                        if ctrl.ShowMap then
                            local _, pos = t_util:GetRandomItem(data.pos_list)
                            if pos then
                                h_util:PlaySound("learn_map")
                                TheFrontEnd:PopScreen()
                                local fn_intor = Mod_ShroomMilk.Func.AddIconIndicator
                                if fn_intor then
                                    fn_intor(icon, pos)
                                end
                                ctrl:ShowMap(Vector3(pos.x, 0, pos.z))
                            end
                        end
                    end
                else
                    TheNet:Say(STRINGS.LMB .. " 此世界有 " .. count .. "处 " .. name .. "。")
                end
            end
        }
    end)
end

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegHMap(save_id, str_show, "是否显示 " .. str_show .. " 的图标", function()
        return save_data.sw
    end, fn_save("sw"))
end)

local function fn_left()
    m_util:AddBindShowScreen({
        title = str_show,
        id = "hx_" .. save_id,
        data = PackScreenData()
    })()
end

local TEMPLATES = require "widgets/redux/templates"
AddSimPostInit(function()
    AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
        self[save_id] = self.root:AddChild(TEMPLATES.StandardButton(fn_left, str_show .. "！", {200, 50}))
        self[save_id]:SetPosition(500, -275)
    end)
end)

m_util:AddBindConf(save_id, fn_left, nil,
    {str_show, img_show, STRINGS.LMB .. '检查地形' .. STRINGS.RMB .. '？？？', true, fn_left, function()
        h_util:CreatePopupWithClose(nil, "请启用风华篇开启更多功能！", {{
            text = "订阅模组",
            cb = function()
                VisitURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3176873821", false)
            end
        }, {
            text = h_util.ok
        }})
    end, 2001})

Mod_ShroomMilk.Func.ScanWorldNodes = fn_left
Mod_ShroomMilk.Func.GetNodeIcons = fn_get_node
