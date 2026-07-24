local save_id, str_show = "rt_take", "配方拿取"
local default_data = {
    sw = true,
    btn_conf = MOUSEBUTTON_RIGHT,
    range = 60
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local bantags = {'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player', 'stewer', 'backpack', 'trader', 'lamp'}
local function Say(str)
    u_util:Say(str, nil, nil, nil, true)
end


local function GetCanTake(item)
    local can_cont
    local can_slot = e_util:CanPutInItem(ThePlayer, item)
    if can_slot then
        can_cont = ThePlayer
    else
        local backpack = p_util:GetBackpack()
        can_slot = e_util:CanPutInItem(backpack, item)
        if can_slot then
            can_cont = backpack
        end
    end
    return can_cont, can_slot
end

local function SearchAndTakePrefab(prefab, amount_has, amount_need)
    local func_has = Mod_ShroomMilk.Func.HasPrefabWithBox
    local func_refresh = Mod_ShroomMilk.Func.RefreshBoxMemory
    local pusher = m_util:GetPusher()
    if not (func_has and pusher and prefab) then
        return
    end
    local name = e_util:GetPrefabName(prefab)
    local box = e_util:FindEnt(nil, nil, save_data.range_search, {"_container"}, bantags, nil, nil, function(cont)
        return func_has(cont, prefab, true) and p_util:GetMouseActionSoft({"RUMMAGE"}, cont)
    end)
    if box then
        Say("正在搜寻 " .. name)
    else
        return Say("我找不到 " .. name)
    end
    p_util:ReturnActiveItem()
    pusher:RegNowTask(function(player, pc)
        d_util:OpenContainer(box)
        local info = p_util:GetSlotFromAll(prefab, nil, function(item, cont, slot)
            return cont == box
        end, {"container"})
        if info then
            local can_cont, can_slot = GetCanTake(info.item)
            if can_cont then
                p_util:MoveItemFromCountOfSlot(info.slot, box, can_cont, amount_need)
                Say("拿取完成")
            else
                Say("没有格子了")
            end
        else
            Say("没有这个物品")
        end
        func_refresh(box)
        return true
    end)
end


AddClassPostConstruct("widgets/ingredientui", function(self, ...)
    local _OnMouseButton = self.OnMouseButton
    function self.OnMouseButton(self, button, down, ...)
        if save_data.sw and button == save_data.btn_conf and down then
            local str = self.quant and self.quant:GetString() or ""
            local amount_has, amount_need = str:match('(%d+)/(%d+)')
            amount_has, amount_need = tonumber(amount_has), tonumber(amount_need)
            if amount_has and amount_need then
                SearchAndTakePrefab(self.recipe_type, amount_has, amount_need)
            end
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)


m_util:AddRightMouseData(save_id, str_show, "是否启用" .. str_show, function()
    return save_data.sw
end, fn_save("sw"), {
    screen_data = {{
        id = "readme",
        label = "使用指南",
        fn = function()
            h_util:CreatePopupWithClose(str_show .. " · 使用指南",
                "右键(默认)点击物品配方，\n自动从箱子中拿取指定数量物品", {{
                    text = h_util.ok
                }})
        end,
        hover = "点击查看教程",
        default = true
    }, {
        id = "btn_conf",
        label = "绑定按键:",
        fn = fn_save("btn_conf"),
        type = "radio",
        hover = "设定触发按键",
        default = fn_get,
        data = h_util:SetMouseSecond()
    }, {
        id = "range",
        label = "搜寻范围:",
        fn = fn_save("range"),
        type = "radio",
        hover = "搜寻箱子的范围:",
        default = fn_get,
        data = require("data/valuetable").range_datatable
    }, {
        id = "readme",
        label = "这是什么？",
        fn = function()
            h_util:CreatePopupWithClose("󰀍" .. str_show .. " · 特别鸣谢󰀍",
                "饥荒真好玩。\n                           —只愿在梦中沉沦永不醒来")
        end,
        hover = "特别鸣谢",
        default = true
    }},
    priority = 99
})
