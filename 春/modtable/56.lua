local save_id, string_mid = "mid_search", "中键加强"
local default_data = {
    btn_conf = MOUSEBUTTON_MIDDLE, 
    onground = true,
    onocean = false,
    range_search = 80,
    order_search = 1,
    force_memory = false
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)


local function SearchAndClickPrefabDetail(prefab, num, onground, onocean)
    if type(prefab) ~= "string" then
        return
    end
    
    local _prefab
    if prefab:sub(1, 10) == "transmute_" then
        _prefab = prefab
        prefab = prefab:sub(11)
    end
    local ents = e_util:FindEnts(nil, nil, save_data.range_search, nil, nil, nil, nil, function(ent)
        return onocean or not ent:IsOnOcean(false)
    end)

    local function GetMouseAct(ent)
        return p_util:GetMouseActionClick(ent)
    end
    local function CheckGround(ent)
        if not onground or (ent and ent.prefab and not ent.prefab:find("^"..prefab.."%d?$")) then
            return
        end
        return GetMouseAct(ent)
    end
    local function CheckBoxShowme(ent)
        local has = ent.ShowMe_chest_table and t_util:GetElement(ent.ShowMe_chest_table, function(_prefab)
            return _prefab:gsub(" ", "") == prefab
        end)
        return has and GetMouseAct(ent)
    end
    local function CheckBoxInsight(ent)
        if e_util:IsContainer(ent) then
            local ins = t_util:GetRecur(ThePlayer, "replica.insight")
            return ins and ins:ContainerHas(ent, prefab, false) and GetMouseAct(ent)
        end
    end
    local function CheckBoxMemory(ent)
        return Mod_ShroomMilk.Func.HasPrefabWithBox and Mod_ShroomMilk.Func.HasPrefabWithBox(ent, prefab) and
                   GetMouseAct(ent)
    end

    local function FindGround()
        return t_util:IGetElement(ents, CheckGround)
    end
    local function FindBox()
        if m_util:EnableShowme() and not save_data.force_memory then
            return t_util:IGetElement(ents, CheckBoxShowme)
        elseif m_util:EnableInsight() and not save_data.force_memory then
            return t_util:IGetElement(ents, CheckBoxInsight)
        else
            return t_util:IGetElement(ents, CheckBoxMemory)
        end
    end
    local data
    if save_data.order_search == 1 then
        data = FindGround() or FindBox()
    elseif save_data.order_search == 2 then
        data = FindBox() or FindGround()
    else
        data = t_util:IGetElement(ents, function(ent)
            if ent.prefab == prefab then
                return GetMouseAct(ent)
            else
                if m_util:EnableShowme() and not save_data.force_memory then
                    return CheckBoxShowme(ent)
                elseif m_util:EnableInsight() and not save_data.force_memory then
                    return CheckBoxInsight(ent)
                else
                    return CheckBoxMemory(ent)
                end
            end
        end)
    end
    if data then
        local act_str = data.act:GetActionString() or ""
        local name = e_util:GetPrefabName(data.target.prefab, data.target) or ""
        u_util:Say(act_str .. " " .. name, nil, "head", nil, true)

        d_util:RemoteClick(data)
        return true
    else
        local ings = t_util:GetRecur(AllRecipes[prefab], "ingredients")
        local _prefab = ings and #ings == 1 and type(ings[1]) == "table" and ings[1].type
        num = num or 0
        if _prefab and num < 4 then
            return SearchAndClickPrefabDetail(_prefab, num + 1, onground, onocean)
        else
            local name = e_util:GetPrefabName(prefab) or ""
            u_util:Say("我找不到 " .. name, nil, "head", nil, true)
        end
    end
end

local function SearchAndClickPrefab(prefab, num)
    return SearchAndClickPrefabDetail(prefab, num, save_data.onground, save_data.onocean)
end


AddClassPostConstruct("widgets/ingredientui", function(self, ...)
    local _OnMouseButton = self.OnMouseButton
    function self.OnMouseButton(self, button, down, ...)
        if button == save_data.btn_conf and down then
            SearchAndClickPrefab(self.recipe_type)
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)

AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function(self, ...)
    local _OnMouseButton = self.OnMouseButton
    function self.OnMouseButton(self, button, down, ...)
        if button == save_data.btn_conf and down then
            if not t_util:GetRecur(self, "recipe_popup.ingredients.focus") then
                SearchAndClickPrefab(self.recipe_name)
            end
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)

AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self, ...)
    local _OnMouseButton = self.OnMouseButton

    function self.OnMouseButton(self, button, down, ...)
        if button == tonumber(save_data.btn_conf) and down then
            local grid = self.recipe_grid
            local skin = self.details_root and self.details_root.skins_spinner
            local prefab
            if grid and grid.focus and grid.shown then
                local index = grid.focused_widget_index + grid.displayed_start_index
                local items = grid.items
                if index and items and items[index] then
                    local recipe = items[index].recipe
                    prefab = recipe and recipe.product
                end
            elseif skin and skin.focus and skin.enabled and skin.shown then
                prefab = skin.recipe and skin.recipe.product
            end
            SearchAndClickPrefab(prefab)
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)

-- ===== 以下为被移除的收纳功能（已注释） =====
--[[
local items_task = {}
local id_task = "_hx_image_tint"

local function AddTint(item, togreen)
    local img = item[id_task]
    if togreen then
        if item:HasTag("fresh") then
            img:SetTint(1, 0, 0, 1)
        else
            img:SetTint(0, 1, 0, 1)
        end
    else
        img:SetTint(1, 1, 1, 1)
    end
end

local function ClearTint()
    t_util:IPairs(items_task, AddTint)
    items_task = {}
end
local bantags = {'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player', 'stewer', 'backpack', 'trader', 'lamp'}
local func_has, func_get
local function AutoSort(player, pc)
    d_util:Wait()
    local _, item = next(items_task)
    if item then
        local slot_data = e_util:IsValid(item) and p_util:GetSlotFromAll(item.prefab, nil, function(ent)
            return item == ent
        end, {"body", "backpack"})
        if slot_data then
            local conts = e_util:FindEnts(nil, nil, save_data.range_search, {"_container"}, bantags)
            
            local conts_not_has = {}
            local cont = t_util:IGetElement(conts, function(cont)
                local container = e_util:GetContainer(cont)
                if not (container and cont:HasOneOfTags({"hutch", "chester", "structure"})) then
                    return
                end
                local cont_slots = container:GetNumSlots()
                if cont_slots < 5 then
                    return
                end
                local data_cont = func_has and func_has(cont, item.prefab) 
                if data_cont then
                    for i = 1, cont_slots do
                        local line = data_cont[tostring(i)]
                        if line then
                            if line.prefab == item.prefab then
                                local stack, max = tonumber(line.stack), tonumber(line.max)
                                if stack and max and stack < max then
                                    return cont
                                end
                            end
                        else
                            return cont
                        end
                    end
                else
                    
                    data_cont = func_get(cont)
                    if data_cont then
                        for i = 1, cont_slots do
                            local line = data_cont[tostring(i)]
                            if not line then
                                
                                table.insert(conts_not_has, cont)
                                return
                            end
                        end
                    else
                        
                        table.insert(conts_not_has, cont)
                        return
                    end
                end
            end)
            if not cont then
                local cont_book, cont_salt, cont_cool, cont_else = {}, {}, {}, {}
                t_util:IPairs(conts_not_has, function(container_ent)
                    if container_ent.prefab == "bookstation" then
                        table.insert(cont_book, container_ent)
                    elseif container_ent:HasTag("saltbox") then
                        table.insert(cont_salt, container_ent)
                    elseif container_ent:HasTag("fridge") then
                        table.insert(cont_cool, container_ent)
                    else
                        table.insert(cont_else, container_ent)
                    end
                end)
                local function CanPutIn(conts)
                    return t_util:IGetElement(conts, function(cont)
                        return e_util:CanPutInItem(cont, item) and cont
                    end)
                end
                cont = CanPutIn(cont_book) or CanPutIn(cont_salt) or CanPutIn(cont_cool) or CanPutIn(cont_else)
            end
            local container = e_util:GetContainer(cont)
            if container then
                while not container:IsOpenedBy(player) do
                    local act, right = p_util:GetMouseActionSoft({"RUMMAGE"}, cont)
                    if not act then
                        break
                    end
                    p_util:DoMouseAction(act, right)
                    
                    d_util:Wait(0.5)
                end
                if container:IsOpenedBy(player) then
                    
                    local num = container:GetNumSlots()
                    local canput
                    for i = 1, num do
                        local _item = container:GetItemInSlot(i)
                        if not _item or e_util:GetStackSize(_item) < e_util:GetMaxSize(_item) then
                            canput = true
                            break
                        end
                    end
                    if canput then
                        p_util:MoveItemFromAllOfSlot(slot_data.slot, slot_data.cont, cont)
                    end
                else
                    AddTint(item)
                    table.removearrayvalue(items_task, item)
                end
            else
                AddTint(item)
                table.removearrayvalue(items_task, item)
            end
        else
            AddTint(item)
            table.removearrayvalue(items_task, item)
        end
    else
        
        return true
    end
end

i_util:AddWorldActivatedFunc(function()
    func_has = Mod_ShroomMilk.Func.HasPrefabWithBox
    func_get = Mod_ShroomMilk.Func.GetMemoryBoxData
end)

AddClassPostConstruct("widgets/invslot", function(self, ...)
    local _OnMouseButton = self.OnMouseButton

    function self.OnMouseButton(self, button, down, ...)
        if button == tonumber(save_data.btn_conf) and down and self.tile then
            local image = self.tile.image
            local item = self.tile.item
            local cont = self.container and self.container.inst
            local pusher = ThePlayer and ThePlayer.components.hx_pusher
            if func_has and image and item and cont and pusher and cont:HasOneOfTags({"player", "backpack"}) then
                item[id_task] = image
                if not pusher then
                    return
                end
                if table.contains(items_task, item) then
                    AddTint(item)
                    table.removearrayvalue(items_task, item)
                else
                    AddTint(item, true)
                    table.insert(items_task, item)
                end
                if #items_task > 0 then
                    if not pusher:GetNowTask() then
                        pusher:RegNowTask(AutoSort, function()
                            ClearTint()
                            u_util:Say("收纳结束")
                        end)
                    end
                else
                    pusher:StopNowTask()
                end
            end
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)
--]]
-- ===== 收纳功能注释结束 =====

local str_default, str_null, str_fuzzy = "哎呀，点我干嘛",
    "精确匹配未能匹配任何结果，试试模糊匹配？", "未能匹配任何结果"
local str_highlight = "您尚未启用【箱子物品高亮】\n请先在【记忆力】中开启此功能！"

local function GetPrefabPrecise(text)
    text = text:lower()
    return t_util:GetElement(STRINGS.NAMES, function(prefab, name)
        return
            type(prefab) == "string" and type(name) == "string" and (prefab:lower() == text or name:lower() == text) and
                {
                    prefab = prefab:lower(),
                    name = name
                }
    end)
end
local function GetPrefabsFuzzy(text)
    local ret = {
        count = 0,
        prefab_table = {},
        name_table = {}
    }
    t_util:Pairs(STRINGS.NAMES, function(prefab, name)
        if type(prefab) == "string" and type(name) == "string" and
            (c_util:IsStrContains(prefab, text) or c_util:IsStrContains(name, text)) then
            ret.count = ret.count + 1
            table.insert(ret.prefab_table, prefab:lower())
            table.insert(ret.name_table, name)
        end
    end)
    return ret
end

local function IsNullCheck(text, value)
    if string.len(text) == 0 then
        return true, str_default
    end
    if value then
        local ret = GetPrefabPrecise(text)
        if ret then
            return false, ret
        else
            return true, str_null
        end
    else
        local ret = GetPrefabsFuzzy(text)
        if ret.count == 0 then
            return true, str_fuzzy
        else
            return false, ret
        end
    end
end

local function GetStr(ret, value)
    if value then
        return "精确搜索 " .. ret.name .. "`" .. ret.prefab .. "`" .. ":\n"
    else
        local count = #ret.name_table
        if count > 9 then
            local name_table = t_util:BuildNumInsert(1, 9, 1, function(i)
                return ret.name_table[i]
            end)
            table.insert(name_table, "...")
            table.insert(name_table, "...")
            return "模糊搜索下列 " .. count .. " 个物品:\n" .. table.concat(name_table, "\n")
        else
            return "模糊搜索下列 " .. count .. " 个物品:\n" .. table.concat(ret.name_table, "\n")
        end
    end
end

local funcs = {
    SavePos = function(pos)
        fn_save("posx")(pos.x)
        fn_save("posy")(pos.y)
    end,
    Highlight = function(text, value)
        local HighlightPrefabs = Mod_ShroomMilk.Func.HighlightPrefabs
        if not m_util:IsTurnOn("brain_chester") or not HighlightPrefabs then
            return str_highlight
        end
        local isnull, ret = IsNullCheck(text, value)
        if isnull then
            return ret
        end
        local str = GetStr(ret, value)
        local count = HighlightPrefabs(value and ret.prefab or ret.prefab_table)
        return str .. "\n已高亮 " .. count .. " 个物品"
    end,
    Click = function(text, value)
        local isnull, ret = IsNullCheck(text, value)
        if isnull then
            return ret
        end
        local str = GetStr(ret, value)
        if t_util:IGetElement(value and {ret.prefab} or ret.prefab_table, function(prefab)
            return SearchAndClickPrefabDetail(prefab, nil, true, true)
        end) then
            return str .. "\n成功查询！"
        else
            return str .. "\n附近没有您要找的物品"
        end
    end,
    Close = function()
        local ClearHighlight = Mod_ShroomMilk.Func.ClearHighlight
        if ClearHighlight then
            ClearHighlight()
        end
        local ui = t_util:GetRecur(ThePlayer, "HUD.controls.hx_search")
        if ui then
            ui:Kill()
        end
    end
}

local Sch = require "widgets/huxi/huxi_search"
local function fn_left()
    local ctrl = t_util:GetRecur(ThePlayer, "HUD.controls")
    if not ctrl then
        return
    end
    if h_util:IsValid(ctrl.hx_search) then
        ctrl.hx_search:Kill()
    else
        ctrl.hx_search = ctrl:AddChild(Sch(funcs, save_data))
    end
end

local fn_right = m_util:AddBindShowScreen({
    title = "超级好用的 " .. string_mid,
    id = save_id,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "自定义",
        fn = function()
            h_util:CreatePopupWithClose(nil, "尚未有人可视化数据，敬请期待。")
        end
    }},
    data = {{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()
            VisitURL("https://www.bilibili.com/video/BV1h2CrB5E6f/", true)
        end
    }, {
        id = "force_memory",
        label = "强制本地记忆",
        hover = "慎重打开，打开后将不再和showme或ins交流!\n此功能将完全由本地控制！",
        fn = fn_save("force_memory"),
        default = fn_get
    }, {
        id = "onground",
        label = "地面搜索",
        fn = fn_save("onground"),
        hover = "是否允许从地上捡起来相关物品",
        default = fn_get
    }, {
        id = "onocean",
        label = "海洋搜索",
        fn = fn_save("onocean"),
        hover = "是否允许从海上捡起来相关物品",
        default = fn_get
    }, {
        id = "order_search",
        label = "搜索顺序：",
        fn = fn_save("order_search"),
        hover = "优先从地上捡还是箱子里面拿？",
        default = fn_get,
        type = "radio",
        data = {{
            data = 1,
            description = "优先地上拿"
        }, {
            data = 2,
            description = "优先箱子取"
        }, {
            data = 3,
            description = "优先距离近"
        }}
    }, {
        id = "range_search",
        label = "查找范围：",
        fn = fn_save("range_search"),
        hover = "查找物品的范围, 20已经到全屏了",
        default = fn_get,
        type = "radio",
        data = t_util:BuildNumInsert(1, 20, 1, function(i)
            return {
                data = i * 4,
                description = i .. " 格地皮"
            }
        end)
    }, {
        id = "btn_conf",
        label = "绑定按键：",
        fn = fn_save("btn_conf"),
        hover = "设置相关绑定按键",
        default = fn_get,
        type = "radio",
        data = h_util:SetMouseSecond()
    }, {
        id = "reset_ui",
        label = "重置位置",
        fn = function()
            local ui = t_util:GetRecur(ThePlayer, "HUD.controls.hx_search")
            if h_util:IsValid(ui) then
                ui:SetUIPos(true)
            else
                h_util:CreatePopupWithClose(nil, "尚未启用搜索窗口！")
            end
        end,
        hover = "重置UI位置",
        default = true
    }}
})

m_util:AddBindConf(save_id, fn_left, nil,
    {string_mid, "book_horticulture_upgraded", STRINGS.LMB .. '搜索面板' .. STRINGS.RMB .. '高级设置', true,
     fn_left, fn_right, 9994})
Mod_ShroomMilk.Func.OpenMidSearchUI = fn_left


AddClassPostConstruct("widgets/redux/craftingmenu_pinbar", function(self, ...)
    local _OnMouseButton = self.OnMouseButton
    function self.OnMouseButton(self, button, down, ...)
        if button == save_data.btn_conf and down then
            if t_util:GetRecur(self, "open_menu_button.focus") then
                SearchAndClickPrefabDetail("seeds", nil, true)
            end
        end
        return _OnMouseButton(self, button, down, ...)
    end
end)