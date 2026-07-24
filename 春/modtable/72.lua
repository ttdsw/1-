local save_id, str_double = "rt_double", "双击传送"
local default_data = {
    sw = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local ignorestr = {"SOUL", "FREESOUL"} 
local count_tele = 2
local string_tele


local function flush_action_str(num)
    count_tele = num and count_tele + num or 2
    if not string_tele then return end
    STRINGS.ACTIONS.BLINK.GENERIC = string.format(
        string_tele .. " (%s)",
        count_tele
    )
end



i_util:AddSessionLoadFunc(function()
    if not string_tele then
        string_tele = STRINGS.ACTIONS and STRINGS.ACTIONS.BLINK and STRINGS.ACTIONS.BLINK.GENERIC
        string_tele = type(string_tele) == "string" and string_tele or "传送"
    end
    if save_data.sw then
        flush_action_str()
    end
end)



i_util:AddRightClickFunc(function(pc, player, down, act, ent_mouse)
    if down and act
    and act.action == ACTIONS.BLINK
    and not table.contains(ignorestr, act.action.strfn(act))
    and save_data.sw
    then
        if count_tele > 0 then
            flush_action_str(-1)
            player:DoTaskInTime(0.5, function()
                flush_action_str()
            end)
        end
        return count_tele > 0
    end
end)




m_util:AddRightMouseData(save_id,str_double, "是否启用 "..str_double, function()
    return save_data.sw
end, function(value)
    fn_save("sw")(value)
    if value then
        flush_action_str()
    else
        STRINGS.ACTIONS.BLINK.GENERIC = string_tele
    end
end)