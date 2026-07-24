local save_id, str_staff = "sw_castspell", "精准施法"
local default_data = {
    sw = true,
    staffs = {"yellowstaff", "opalstaff", "trident"}
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function GetSpellAct(ent)
    local item = p_util:GetActiveItem() or p_util:GetEquip("hands")
    if item and table.contains(save_data.staffs, item.prefab) then
        local pos = e_util:IsValid(ent) and ent:GetPosition() or TheInput:GetWorldPosition()
        local act = pos and p_util:GetAction("pos", "CASTSPELL", true, item, nil, pos)
        return act, pos
    end
end


i_util:AddRightClickFunc(function(pc, player, down, act, ent)
    if not (down and ent and save_data.sw) then
        return
    end
    local act, pos = GetSpellAct(ent)
    if act then
        p_util:DoAction(act, RPC.RightClick, act.action.code, pos.x, pos.z)
    end
end)


i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if item_world and save_data.sw then
        local act, pos = GetSpellAct(item_world)
        if act then
            local act_str = t_util:GetRecur(STRINGS, "ACTIONS.LOOKAT.GENERIC")
            if act_str and str:rfind_plain(act_str) then
                return str:gsub(act_str, h_util:GetStringKeyBoardMouse(MOUSEBUTTON_RIGHT) .. str_staff)
            end
        end
    end
end)

local fn_show, fn_text = r_util:InitPack(save_data, fn_get, fn_save, function()
    fn_save("sw")(not save_data.sw)
    u_util:Say(str_staff, save_data.sw, nil, nil, true)
end, "sw_key")


m_util:AddRightMouseData(save_id, str_staff, "是否启用 " .. str_staff, function()
    return save_data.sw
end, function(value)
    fn_save("sw")(value)
end, {
    screen_data = {{
        id = "sw_key",
        label = "开关按键：",
        hover = "【精准施法】的快速开关快捷键",
        type = "textbtn",
        default = fn_show,
        fn = fn_text("sw_key", str_staff)
    }, {
        id = "list_self",
        label = "自选法杖名单",
        hover = "名单中的法杖将启用自动施法",
        prefab = default_data.staffs[1],
        type = "imgstr",
        fn = m_util:AddBindShowScreen{
            title = "自选法杖名单",
            id = "list_self",
            data = m_util:FuncListRemove(save_data, "staffs", fn_save, function(name)
                return "法杖：" .. name
            end, "你确定要移除该法杖吗？", function(name, prefab)
                return "法杖代码：" .. prefab .. "\n点击移除出名单！"
            end, "该法杖为模组法杖，无法显示图标\n点击移除出名单！"),
            fn_active = true,
            dontpop = true,
            icon = {{
                id = "add",
                prefab = "mods",
                hover = "点击添加要精确施法的法杖",
                fn = m_util:FuncListAdd(save_data, fn_save, "staffs", "精确施法", "法杖")
            }, {
                id = "reset_repair",
                prefab = "revert2",
                hover = "点击重置要精确施法的法杖清单",
                fn = m_util:FuncListReset(save_data, default_data, fn_save,
                    "你确定要重置精确施法的法杖清单吗？", "staffs")
            }}
        }
    }}
})
