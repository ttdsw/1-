local save_id, str_track = "rt_dirtpile", "自动翻脚印"
local default_data = {
    sw = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local prefabs_before = {"dirtpile"}
local prefabs_after = {"animal_track"}
local prefabs = t_util:MergeList(prefabs_before, prefabs_after)
local actions = {"ACTIVATE"}
local ent_before
local function GetIconInfo()
    local season = TheWorld and TheWorld.state and TheWorld.state.season
    local img = season == "winter" and "koalefant_winter" or "koalefant_summer"
    local xml, tex = h_util:GetPrefabAsset(img)
    return {
        xml = xml,
        tex = tex,
        text = STRINGS.NAMES.ANIMAL_TRACK,
        describe = "点击自动翻脚印"
    }
end


local function RefreshIcon()
    local saver = m_util:GetSaver()
    if not saver then return end
    
    if not save_data.sw or not e_util:IsValid(ent_before) then
        return saver:RemoveStat(save_id, save_id)
    end
    if saver:HasStatUI(save_id, save_id) then
        
        saver:ChanStatUI(save_id, save_id, GetIconInfo())
    else
        
        saver:AddStat(save_id, save_id, GetIconInfo())
        saver:SetTimerConfig()
    end
end


m_util:AddRightMouseData(save_id, str_track, "是否启用自动翻脚印", function()
    return save_data.sw
end, function(value)
    fn_save("sw")(value)
    RefreshIcon()
end)



t_util:IPairs(prefabs_before, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0, function()
            local dist = e_util:GetDist(inst)
            if dist and dist < 70 then
                ent_before = inst
                RefreshIcon()
            end
        end)
        inst:ListenForEvent("onremove", function()
            if ent_before == inst then
                ent_before = nil
                i_util:DoTaskInTime(0.5, RefreshIcon)
            end
        end)
    end)
end)


local function AutoFn()
    local pusher = ThePlayer and ThePlayer.components.hx_pusher
    if not pusher then return end
    
    pusher:RegNowTask(function()
        if p_util:GetActiveItem() then
            return true
        end
        
        local flag
        if e_util:IsValid(ent_before) then
            local act, right = p_util:GetMouseActionSoft(actions, ent_before)
            if act then
                p_util:DoMouseAction(act, right)
                flag = true
            end
        end
        if flag then
            d_util:Wait()
        else
            local time = GetTime()
            local act
            repeat
                d_util:Wait()
                act = e_util:IsValid(ent_before) and p_util:GetMouseActionSoft(actions, ent_before)
            until GetTime() - time > 2 or act
            if not act then
                return true
            end
        end
    end)
end



i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    saver:RegStat(save_id, "脚印标记", "是否显示 脚印标记 的图标", function()
        return save_data.sw
    end, fn_save("sw"), {fn_left = function()
       u_util:Say("寻找可疑的足迹...")
       AutoFn()
    end}, {priority = -100})
end)



i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if item_world and table.contains(prefabs, item_world.prefab) and save_data.sw and type(str) == "string" and e_util:IsValid(ent_before) then
        return h_util:GetStringKeyBoardMouse(MOUSEBUTTON_RIGHT) .. str_track.."\n"..str
    end
end)



i_util:AddRightClickFunc(function(pc, player, down, act_right, ent_mouse)
    if not (ent_mouse and table.contains(prefabs, ent_mouse.prefab) and save_data.sw and down and e_util:IsValid(ent_before)) then return end
    AutoFn()
end)


Mod_ShroomMilk.Func.ACTIVATE_ANIMAL_TRACK = AutoFn
