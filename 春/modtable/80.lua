local Intor = require "widgets/huxi/huxi_indicator"
local V = require "data/valuetable"
local list_boss = require "data/itemlist_boss"
list_boss = t_util:MergeList(list_boss)
t_util:Sub(list_boss, "deciduoustree")      
t_util:Add(list_boss, "beequeenhivegrown")
local list_dirtpile = {"dirtpile"}
local list_wormhole = require("data/mapicons").wormhole_data
local list_item = require "data/itemlist_indicator"
local list_inbox = {"inspectaclesbox","inspectaclesbox2",}
local toy_trinket_nums = {1,2,7,10,11,14,18,19,42,43,}
local toys =
{
    "lost_toy_1",
    "lost_toy_2",
    "lost_toy_7",
    "lost_toy_10",
    "lost_toy_11",
    "lost_toy_14",
    "lost_toy_18",
    "lost_toy_19",
    "lost_toy_42",
    "lost_toy_43",
}
local list_sea = t_util:MergeList(toys, {"underwater_salvageable", "pirate_stash", "messagebottle"})
local list_prefab = t_util:MergeList(list_boss, list_dirtpile, list_sea, list_item, list_wormhole, list_inbox)


local save_id, str_show = "sw_indicator", "方向指示"
local default_data = {
    sw = true,
    min_scale = 0.5,
    max_scale = 1,
    clickable = true,
    color_boss = "番茄色",
    color_dirtpile = "淡紫色",
    color_sea = "呼吸蓝",
    color_item = "白色",
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local Intors = {}

local function KillIndicator(inst)
    if t_util:GetRecur(Intors[inst], "Kill") then
        Intors[inst]:Kill()
    end
    Intors[inst] = nil
end


local dist_click = 60
local function fn_walk(inst)
    return function()
        local data = p_util:GetMouseActionClick(inst)
        if not data then return end
        local act_str = data.act:GetActionString() or ""
        local name = e_util:GetPrefabName(data.target.prefab, data.target) or ""
        u_util:Say(act_str .. " " .. name, nil, "head", nil, true)
        d_util:RemoteClick(data)
    end
end


local function AddIndicator(inst)
    KillIndicator(inst)
    if save_data.sw then
        local root = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.under_root
        if not root then return end
        local xml, tex, name = h_util:GetPrefabAsset(inst.prefab)
        local fn_left = save_data.clickable and fn_walk(inst)
        local meta = {min_scale = save_data.min_scale, max_scale = save_data.max_scale, color = save_data.color_item}
        local prefab = inst.prefab

        if table.contains(list_boss, prefab) then
            meta.color = save_data.color_boss
        elseif table.contains(list_dirtpile, prefab) then
            meta.color = save_data.color_dirtpile
            if prefab == "dirtpile" then
                local func = Mod_ShroomMilk.Func.ACTIVATE_ANIMAL_TRACK
                if func and fn_left then
                    fn_left = func
                end
            end
        elseif table.contains(list_sea, prefab) then
            meta.color = save_data.color_sea
            if prefab == "underwater_salvageable" then
                xml, tex, name = h_util:GetPrefabAsset("sunkenchest")
            end
        elseif table.contains(list_inbox, prefab) then
            xml, tex, name = h_util:GetPrefabAsset("inspectacleshat")
            name = e_util:GetPrefabName(prefab)
        elseif table.contains(list_wormhole, prefab) then
            local func = Mod_ShroomMilk.Func.GetWormholeData
            if func then
                local data = func(inst)
                if data then
                    meta.color = data.rgb
                    xml, tex = h_util:GetPrefabAsset(data.icon)
                    name = inst.name.." "..data.num
                else
                    local skin_bd = inst.AnimState and inst.AnimState:GetSkinBuild()
                    if skin_bd and skin_bd ~= "" then
                        xml, tex = h_util:GetPrefabAsset(skin_bd)
                    end
                end
            else
                local skin_bd = inst.AnimState and inst.AnimState:GetSkinBuild()
                if skin_bd and skin_bd ~= "" then
                    xml, tex = h_util:GetPrefabAsset(skin_bd)
                end
            end
        elseif prefab == "mandrake_planted" then
            xml, tex, name = h_util:GetPrefabAsset("mandrake")
        end
        Intors[inst] = root:AddChild(Intor(inst, xml, tex, name, {fn_left = fn_left}, meta))
    else
        Intors[inst] = true
    end
end


local function AddModIndicator(inst, xml, tex, name, funcs, meta)
    if save_data.sw then
        local root = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.under_root
        if not root then return end
        local meta_fill = {min_scale = save_data.min_scale, max_scale = save_data.max_scale, color = save_data.color_item}
        local funcs_fill = {fn_left = save_data.clickable and fn_walk(inst)}
        root:AddChild(Intor(inst, xml, tex, name, t_util:MergeMap(funcs_fill, funcs or {}), t_util:MergeMap(meta_fill, meta or {})))
    end
end


local function AddIconIndicator(icon, pos, funcs, meta)
    local xml, tex, name = h_util:GetPrefabAsset(icon)
    if xml then
        local funcs_fill = {fn_left = function(ui, target) ui:Kill() end}
        local inst = e_util:SpawnNull()
        inst.entity:AddTransform()
        inst:AddTag("FX")
        inst.Transform:SetPosition(pos.x, 0, pos.z)
        AddModIndicator(inst, xml, tex, name, t_util:MergeMap(funcs_fill, funcs or {}), meta)
    end
end

Mod_ShroomMilk.Func.AddModIndicator = AddModIndicator
Mod_ShroomMilk.Func.AddIconIndicator = AddIconIndicator

local function fn_set(id)
    return function(val)
        fn_save(id)(val)
        t_util:Pairs(Intors, AddIndicator)
    end
end


local function ListenForInst(inst)
    local pusher = m_util:GetPusher()
    if not pusher then return end
    pusher:RegNearStart(inst, function()
        AddIndicator(inst)
    end, function()
        KillIndicator(inst)
    end)
end

t_util:IPairs(list_prefab, function(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0, ListenForInst)
    end)
end)

local function fn_left()
    save_data.sw = not save_data.sw
    u_util:Say(str_show, save_data.sw)
    t_util:Pairs(Intors, AddIndicator)
    fn_set("sw")(save_data.sw)
end

local scale_data = t_util:BuildNumInsert(0.1, 4, 0.1, function(i)
    return {data = i, description = i}
end)
local screen_data = {
    {
        id = "sw",
        label = "总开关",
        hover = "是否显示指示器",
        default = fn_get,
        fn = fn_set("sw")
    },
    {
        id = "clickable",
        label = "支持点击",
        hover = "点击指示器自动到达",
        default = fn_get,
        fn = fn_set("clickable")
    },
    {
        id = "min_scale",
        label = "最小缩放：",
        hover = "方向标记的最小大小，默认 " .. default_data.min_scale,
        default = fn_get,
        type = "radio",
        data = scale_data,
        fn = fn_set("min_scale")
    },
    {
        id = "max_scale",
        label = "最大缩放：",
        hover = "方向标记的最大大小，默认 " .. default_data.max_scale,
        default = fn_get,
        type = "radio",
        data = scale_data,
        fn = fn_set("max_scale")
    },{
        id = "color_boss",
        label = "Boss颜色：",
        hover = "Boss的指示器颜色，默认 " .. default_data.color_boss,
        default = fn_get,
        type = "radio",
        data = V.RGB_datatable,
        fn = fn_set("color_boss"),
    },{
        id = "color_dirtpile",
        label = "足迹颜色：",
        hover = "足迹的指示器颜色，默认 " .. default_data.color_dirtpile,
        default = fn_get,
        type = "radio",
        data = V.RGB_datatable,
        fn = fn_set("color_dirtpile"),
    },{
        id = "color_sea",
        label = "海洋宝物颜色：",
        hover = "海洋宝物的指示器颜色，默认 " .. default_data.color_sea,
        default = fn_get,
        type = "radio",
        data = V.RGB_datatable,
        fn = fn_set("color_sea"),
    },{
        id = "color_item",
        label = "其他颜色：",
        hover = "其他指示器颜色，默认 " .. default_data.color_item,
        default = fn_get,
        type = "radio",
        data = V.RGB_datatable,
        fn = fn_set("color_item"),
    },
}
local fn_right = m_util:AddBindShowScreen{
    title = str_show,
    id = "hx_" .. save_id,
    data = screen_data,
    icon = 
    {{
        id = "add",
        prefab = "mods",
        hover = "点击添加要方向指示的实体！",
        fn = function()
            h_util:CreatePopupWithClose(str_show, "尚未有人定制此功能...")
        end,
    }}
}
m_util:AddBindConf(save_id, fn_left, nil, {str_show, "arrowsign_post_factory",
                                           STRINGS.LMB .. '快捷开关' .. STRINGS.RMB .. '高级设置', true, fn_left,
                                           fn_right})
