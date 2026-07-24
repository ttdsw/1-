if m_util:IsServer() then
    return
end
local save_id, string_fish = "sw_fishname", "海钓助手"
local seasons = {
    isspring = {
        color = "春绿色",
        label = "春季"
    },
    issummer = {
        color = "洋李色",
        label = "夏季"
    },
    isautumn = {
        color = "金黄色",
        label = "秋季"
    },
    iswinter = {
        color = "半白",
        label = "冬季"
    }
}
local default_data = {
    fishname = true,
    seasonal = "番茄色",
    sw = true,
    text = true,
    keep = true
}
t_util:Pairs(seasons, function(season, data)
    default_data[season] = data.color
end)
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local seasonal_fish = {"oceanfish_medium_8", "oceanfish_small_6", "oceanfish_small_7", "oceanfish_small_8"}
local function AddFishName(fish)
    local label = fish._hx_label or h_util:CreateLabel(fish, nil, nil, CHATFONT_OUTLINE, 30)
    local state = TheWorld and TheWorld.state
    local prefab = label and state and fish.prefab
    if not prefab then
        return
    end
    label:SetText(save_data.fishname and fish.name or "")

    if table.contains(seasonal_fish, prefab) then
        label:SetColor(save_data.seasonal)
    else
        local s = t_util:GetElement(seasons, function(s)
            return state[s] and s
        end)
        if s then
            label:SetColor(save_data[s])
        end
    end
end
for i = 1, 9 do
    AddPrefabPostInit("oceanfish_medium_" .. i, AddFishName)
    AddPrefabPostInit("oceanfish_small_" .. i, AddFishName)
end
local data_rgb = require("data/valuetable").RGB_datatable
local screen_data = {{
    id = "bilibili",
    prefab = "bilibili",
    type = "imgstr",
    label = "教程演示",
    hover = "点击查看视频教程或功能演示",
    fn = function()
        VisitURL("https://www.bilibili.com/video/BV16FUZBEE32/", true)
    end
}, {
    id = "fishname",
    label = "显示鱼群名字",
    fn = function(v)
        fn_save("fishname")(v)
        local fishes = e_util:FindEnts(nil, nil, nil, {"oceanfishable", "oceanfishinghookable"}, {'INLIMBO', 'player'})
        t_util:IPairs(fishes, AddFishName)
    end,
    hover = "杂鱼~ 杂鱼~",
    default = fn_get
}, {
    id = "seasonal",
    label = "季节鱼颜色:",
    fn = fn_save("seasonal"),
    hover = "四季鱼群名字对应颜色",
    default = fn_get,
    type = "radio",
    data = data_rgb
}}
t_util:Pairs(seasons, function(season, dp)
    table.insert(screen_data, {
        id = season,
        label = dp.label .. "鱼颜色：",
        fn = fn_save(season),
        hover = dp.label .. "鱼群名字对应颜色",
        default = fn_get,
        type = "radio",
        data = data_rgb
    })
end)

local function Say(...)
    if save_data.text then
        u_util:Say(...)
    end
end
i_util:AddRightClickFunc(function(pc, player, down, act, ent)
    if not (not down and save_data.sw and act and act.action == ACTIONS.OCEAN_FISHING_CAST and act.pos) then
        return
    end
    local pos_click = act.pos:GetPosition()
    local equip = p_util:GetEquip("hands")
    local pusher = player.components.hx_pusher
    if not (pos_click and pusher and equip) then
        return
    end
    Say(string_fish, "启动")
    local x, z = pos_click.x, pos_click.z
    local fish_caught
    pusher:RegNowTask(function(player, pc)
        local rod = t_util:GetRecur(equip, "replica.oceanfishingrod")
        if not (e_util:IsValid(equip) and rod) then
            return
        end
        local fish = rod:GetTarget()
        local anim = e_util:GetAnim(fish)
        if anim and fish:HasTag("oceanfishable") and
            (anim:find("walk_") or anim:find("catching_") or anim:find("struggle_")) or
            (fish and fish.prefab == "wobster_sheller") then
            act = p_util:GetAction("pos", {"OCEAN_FISHING_REEL", "OCEAN_FISHING_CATCH"}, true, equip, nil, pos_click)
            if act then
                fish_caught = true
                p_util:DoAction(act, RPC.ControllerAltActionButtonPoint, act.action.code, x, z, false, false)
            end
        elseif fish_caught then
            if save_data.keep then
                local p_pos = player:GetPosition()
                if c_util:GetDist(p_pos.x, p_pos.z, x, z) < 40 then
                    act = p_util:GetAction("pos", "OCEAN_FISHING_CAST", true, equip, nil, pos_click)
                    if act then
                        p_util:DoAction(act, RPC.ControllerAltActionButtonPoint, act.action.code, x, z, false, false)
                    end
                else
                    return true
                end
            else
                return true
            end
        end
        d_util:Wait()
    end, function()
        Say(string_fish, "结束")
    end, "keyboard")
end)

local screen_fish = {{
    id = "sw",
    label = string_fish,
    fn = fn_save("sw"),
    hover = "启用或禁用自动钓鱼",
    default = fn_get
}, {
    id = "keep",
    label = "启用续钓",
    fn = fn_save("keep"),
    hover = "【海钓助手】附属功能\n钓了一条后是否继续抛竿",
    default = fn_get
}, {
    id = "text",
    label = "提示文字",
    fn = fn_save("text"),
    hover = "【海钓助手】附属功能\n是否显示关于钓鱼的文字提示",
    default = fn_get
}}
t_util:IPairs(screen_fish, function(data)
    table.insert(screen_data, data)
end)

local func_right = m_util:AddBindShowScreen({
    title = string_fish,
    id = "hx_" .. save_id,
    data = screen_data,

    icon = {{
        id = "add",
        prefab = "mods",
        hover = "鱼饵查询",
        fn = function()
            h_util:CreatePopupWithClose(nil, "该功能尚未有人定制，敬请期待...")
        end
    }}
})

m_util:AddBindConf(save_id, func_right, nil,
    {string_fish, "oceanfish_small_7_inv", STRINGS.LMB .. '杂鱼~ 杂鱼~', true, func_right})
