if m_util:IsServer() then
    return
end
local save_id = "sw_autorow"
local default_data = {
    sw = true,
    frame = 3
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

i_util:AddRightClickFunc(function(pc, player, down, act)
    if not (down and save_data.sw and act) then
        return
    end
    if act.action == ACTIONS.ROW or act.action == ACTIONS.ROW_FAIL then
        local pusher = player.components.hx_pusher
        local boat = TheWorld.Map:GetPlatformAtPoint(player:GetPosition():Get())
        local pos_act = act:GetActionPoint()
        local oar = p_util:GetEquip("hands")
        if pusher and e_util:IsValid(boat) and pos_act and oar then
            local pos_boat = boat:GetPosition()
            local pos_rela = pos_act - pos_boat
            local prefab = oar.prefab
            pusher:RegNowTask(function()
                Sleep(save_data.frame * FRAMES)
                local hands = p_util:GetEquip("hands")
                
                if hands and hands.prefab == prefab then
                    if e_util:IsValid(boat) then
                        local pos = boat:GetPosition() + pos_rela
                        local act_row = ACTIONS.ROW
                        p_util:DoAction(BufferedAction(act.doer, act.target, act_row, act.invobject, pos),
                            RPC.RightClick, act_row.code, pos.x, pos.z, act.target, act.rotation, true, nil, nil,
                            act.action.mod_name)
                    else
                        return true
                    end
                else
                    local _oar = p_util:GetItemFromAll(prefab)
                    if _oar then
                        p_util:Equip(_oar)
                    else
                        return true
                    end
                end
            end)
        end
    end
end)
local frame_datatable = require("data/valuetable").frame_datatable
local screen_data = {{
    id = "sw",
    label = "划水开关",
    fn = fn_save("sw"),
    hover = "开启或关闭自动划船",
    default = fn_get
}, {
    id = "frame",
    label = "划水间隔",
    fn = fn_save("frame"),
    hover = "默认是 " .. default_data.frame .. " 帧, 设置越小越快",
    default = fn_get,
    type = "radio",
    data = frame_datatable
}, {
    id = "bilibili",
    prefab = "bilibili",
    type = "imgstr",
    label = "教程演示",
    hover = "点击查看视频教程或功能演示",
    fn = function()
        VisitURL("https://www.bilibili.com/video/BV1U92DB3E1M/", true)
    end
}}
local func_right = m_util:AddBindShowScreen{
    title = "自动划船",
    id = "hx_" .. save_id,
    data = screen_data,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "船控制",
        fn = function()
            h_util:CreatePopupWithClose(nil, "该功能尚未有人定制：船UI控制")
        end
    }}
}
local function func_left()
    local state = not save_data.sw
    fn_save("sw")(state)
    u_util:Say("自动划船", state)
end
m_util:AddBindConf(save_id, func_left, nil,
    {"自动划船", "oar_monkey", STRINGS.LMB .. '快速开关' .. STRINGS.RMB .. '高级设置', true, func_left,
     func_right})
