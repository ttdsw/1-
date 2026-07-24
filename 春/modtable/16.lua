if m_util:IsServer() then
    return
end

local save_id, string_say = "sw_autosort", "物品整理"
local default_data = {
    merge = true, 
    delay = 2, 

    st_chest = true, 
    st_bp = true,
    st_inv = true,

    pl_chest = false,
    pl_box = false
}


local data_ingre = require("data/itemlist_material")

local configdata = {
    ingre = {
        label = "基础材料",
        hover = "【T键控制台】的[材]目录下的物品都算材料",
        pos = "inv",
        we = 2,
        func = function(item)
            local prefab = item.prefab
            return t_util:IGetElement(data_ingre, function(ingre)
                return prefab == ingre
            end)
        end
    },
    food = {
        label = "食物",
        hover = "所有右键动作为[吃]的物品",
        pos = "bp",
        we = 2,
        func = function(item)
            return p_util:GetAction("inv", "eat", true, item)
        end
    },
    equip = {
        label = "装备",
        hover = "所有可以装备的物品",
        pos = "inv",
        we = -1,
        func = function(item)
            return e_util:GetItemEquipSlot(item)
        end
    },
    mod = {
        label = "模组物品",
        hover = "不是饥荒原版的内容",
        pos = "bp",
        we = -1,
        func = function(item)
            return m_util:IsModPrefab(item.prefab)
        end
    },
    cont = {
        label = "盒子",
        hover = "可以装其他物品的容器",
        pos = "inv",
        we = 1,
        func = function(item)
            return e_util:GetContainer(item)
        end
    },
    other = {
        label = "除此之外",
        pos = "bp",
        we = 0,
        hover = "所有不在上述分类的物品",
        func = function()
        end
    }
}
local function GetWeID(id)
    return "we_" .. id
end
local function GetPlID(id)
    return "pos_" .. id
end
local cates_we = t_util:PairToIPair(configdata, function(id)
    return id
end)
t_util:Pairs(configdata, function(id, data)
    default_data[GetWeID(id)] = data.we
    default_data[GetPlID(id)] = data.pos
end)
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function fn_merge(slots_data)
    slots_data = slots_data or {}
    local slots_len = #slots_data
    if slots_len == 0 then
        return true
    end
    for i, slot_data in ipairs(slots_data) do
        local item = slot_data.item
        local size_max, size_stack = e_util:GetMaxSize(item), e_util:GetStackSize(item)
        if size_stack < size_max then
            local item_active = p_util:GetActiveItem()
            if item_active and item_active.prefab == item.prefab then
                if d_util:PutActiveItemInSlot(slot_data.cont, slot_data.slot, FRAMES, save_data.delay) then
                    u_util:Say(string_say, "放置物品 " .. item_active.name .. " 超时", nil, "红色", true)
                    return true
                end
                return
            else
                for j = i + 1, slots_len do
                    local item_get = slots_data[j].item
                    if item_get.prefab == item.prefab then
                        if d_util:TakeActiveItem(item_get, FRAMES, save_data.delay) then
                            u_util:Say(string_say, "拿起物品 " .. item_get.name .. " 超时", nil, "红色", true)
                            return true
                        end
                        return
                    end
                end
            end
        end
        if i >= slots_len then
            return true
        end
    end
end

local function GetSlotsData(order)
    return p_util:GetSlotsFromAll(nil, nil, function(_, cont)
        local buildname = cont.AnimState and cont.AnimState:GetBuild()
        return not cont:HasTag("structure") or (not buildname or not buildname:match("_upgraded_"))
    end, order) or {}
end

_G.TB = GetSlotsData

local function fn_tidy()
    local Cates = {}
    t_util:IPairs(cates_we, function(cate)
        Cates[cate] = {}
    end)
    
    table.sort(cates_we, function(a, b)
        return (save_data[GetWeID(a)] or 0) > (save_data[GetWeID(b)] or 0)
    end)
    
    d_util:ReturnActiveItem(FRAMES, save_data.delay)
    
    local data_slots = GetSlotsData({"body", "backpack", "container"})
    local function AddCatesData(data_slot)
        if not data_slot then
            return
        end
        local item = data_slot.item
        local cate = t_util:IGetElement(cates_we, function(cate)
            return configdata[cate].func(item) and cate
        end) or "other"
        table.insert(Cates[cate], data_slot)
    end
    
    t_util:IPairs(data_slots, function(data_slot)
        if data_slot.cont == ThePlayer then
            AddCatesData(save_data.st_inv and data_slot)
        elseif data_slot.cont:HasTag("backpack") then
            AddCatesData(save_data.st_bp and data_slot)
        else
            AddCatesData(save_data.st_chest and data_slot)
        end
    end)
    
    local backpack = p_util:GetBackpack()
    local data_put = {}
    local function PlanPut(data_slot, weigh, cont)
        local container = e_util:GetContainer(cont)
        local capacity = container and container:GetNumSlots() or 0
        if capacity == 0 then
            return data_slot
        end
        if not data_put[cont] then
            data_put[cont] = {}
        end

        local data_put_cont = data_put[cont]

        
        local nullpos_pre, nullpos_last
        local itemcount = 0
        for pos = 1, capacity do
            if data_put_cont[pos] then
                itemcount = itemcount + 1
            else
                if not nullpos_pre then
                    nullpos_pre = pos
                end
                nullpos_last = pos
            end
        end
        local slot = weigh < 0 and nullpos_last or nullpos_pre
        
        if itemcount < capacity and container:CanTakeItemInSlot(data_slot.item, slot) then
            
            
            data_put_cont[slot] = data_slot
        else
            return data_slot
        end
    end
    local error_slot = t_util:IGetElement(cates_we, function(cate)
        table.sort(Cates[cate], function(data_a, data_b)
            local ia, ib = data_a.item, data_b.item
            return ia.prefab > ib.prefab
        end)

        
        return t_util:IGetElement(Cates[cate], function(data_slot)
            local we_cate = save_data[GetWeID(cate)] or 0
            if data_slot.cont == ThePlayer or data_slot.cont == backpack then
                local pos_cate = save_data[GetPlID(cate)]
                
                
                
                if pos_cate == "inv" or pos_cate == 1 then
                    return PlanPut(data_slot, we_cate, save_data.st_inv and ThePlayer) and
                               PlanPut(data_slot, we_cate, save_data.st_bp and backpack)
                else
                    return PlanPut(data_slot, we_cate, save_data.st_bp and backpack) and
                               PlanPut(data_slot, we_cate, save_data.st_inv and ThePlayer)
                end
            else
                return PlanPut(data_slot, we_cate, save_data.st_chest and data_slot.cont)
            end
        end)
    end)
    if error_slot then
        u_util:Say(string_say, "排序物品 " .. error_slot.item.name .. " 失败", nil, "红色", true)
    else
        
        
        
        

        local result = t_util:GetElement(data_put, function(cont, data_put_cont)
            return t_util:GetElement(data_put_cont, function(slot, data_slot)
                
                return d_util:MoveItemInSlot(data_slot.item, cont, slot, FRAMES, save_data.delay) and data_slot
            end)
        end)
        if result then
            u_util:Say(string_say, "迁移物品 " .. result.item.name .. " 超时", nil, "红色", true)
        else
            u_util:Say(string_say, "整理完成", nil, nil, true)
        end
    end
    return true
end

local function fn_sort()
    local pusher = m_util:GetPusher()
    if not pusher then
        return
    end
    local lock_merge_bb, lock_merge_cont 
    pusher:RegNowTask(function()
        
        if save_data.merge and not lock_merge_bb then
            if lock_merge_cont then
                lock_merge_bb = fn_merge(GetSlotsData({"body", "backpack"}))
            else
                lock_merge_cont = fn_merge(GetSlotsData({"container"}))
            end
        else
            return fn_tidy()
        end
        d_util:Wait(FRAMES)
    end, function()
        
    end, "mouse")
end

local screendata_fix = {{
    id = "merge",
    label = "合并堆叠",
    fn = fn_save("merge"),
    hover = "是否先堆叠起来未到达上限的物品",
    default = fn_get
}, {
    id = "st_inv",
    label = "整理物品栏",
    fn = fn_save("st_inv"),
    hover = "是否整理物品栏的物品",
    default = fn_get
}, {
    id = "st_bp",
    label = "整理背包",
    fn = fn_save("st_bp"),
    hover = "是否整理背包内的物品",
    default = fn_get
}, {
    id = "st_chest",
    label = "整理箱子",
    fn = fn_save("st_chest"),
    hover = "是否自动整理箱子",
    default = fn_get
}, {
    id = "delay",
    label = "最大延迟：",
    fn = fn_save("delay"),
    hover = "动作超过此时间视为整理失败",
    default = fn_get,
    type = "radio",
    data = t_util:BuildNumInsert(1, 20, 1, function(i)
        return {
            data = i * 0.5,
            description = (i * 0.5) .. " 秒"
        }
    end)
}}
local to_20 = t_util:BuildNumInsert(-20, 20, 1, function(i)
    local str
    if i > 0.5 or i < -0.5 then
        if i > 0 then
            str = "+ " .. i
        else
            str = "- " .. (-i)
        end
    else
        i = 0
        str = "不设置权重"
    end
    return {
        data = i,
        description = str
    }
end)
local function AddPos(id, label, hover)
    return {
        id = id,
        label = label .. "：",
        fn = fn_save(id),
        hover = hover,
        default = fn_get,
        type = "radio",
        data = {{
            data = "inv",
            description = "优先放 物品栏"
        }, {
            data = "bp",
            description = "优先放 背包"
        }}
    }
end
local function AddWe(id)
    return {
        id = id,
        label = "权重：",
        fn = fn_save(id),
        hover = "权重越大的物品越在前面\n 权重为负数会摆在容器的最后面！",
        default = fn_get,
        type = "radio",
        data = to_20
    }
end
local screendata = {}
local function AddCate(id, ...)
    table.insert(screendata, AddPos(GetPlID(id), ...))
    table.insert(screendata, AddWe(GetWeID(id)))
end
t_util:IPairs({"ingre", "food", "equip", "mod", "cont", "other"}, function(cate)
    AddCate(cate, configdata[cate].label, configdata[cate].hover)
end)

m_util:AddBindConf(save_id, fn_sort)
m_util:AddBindIcon(string_say, "greenamulet", "物品整理的高级设置", true, function()
    local idata = t_util:IGetElement(m_util:LoadReBindData(), function(idata)
        return idata.id == save_id .. modname and idata
    end)
    if idata then
        idata = t_util:MergeMap(idata)
        idata.label = "绑定按键："
        idata.hover = "点击设置绑定按键"
    end
    m_util:AddBindShowScreen({
        title = "物品整理规则",
        id = save_id,
        data = t_util:MergeList({idata}, screendata_fix, screendata)
    })()
end, nil, 8000)
