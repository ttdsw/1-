local save_id, string_cook = "sw_autocook1", "自动烹饪"
local default_data = {
    btn_conf = 1002, 
    range_search = 80,
    showui = true,
    data = {
        
    }
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local StewerFn = {}


local tags = {"structure", "_container", "stewer"}


local function IsStewer(ent)
    if e_util:IsValid(ent) and ent:HasTags(tags) then
        local container = e_util:GetContainer(ent)
        local btn = container and container:GetWidget() and container:GetWidget().buttoninfo
        
        
        return btn and btn.fn and btn.validfn and btn
    end
end

local function Say(what, dontfresh)
    u_util:Say(string_cook, what, nil, nil, not dontfresh)
    return true
end


local function SaveStewerData(cont)
    local container = e_util:GetContainer(cont)
    if not container then
        return
    end
    local prefab = cont.prefab
    if type(prefab) ~= "string" then
        return
    end
    local prefab_data = {}
    local null
    for i = 1, container:GetNumSlots() do
        local item = container:GetItemInSlot(i)
        local prefab = item and item.prefab
        if prefab then
            table.insert(prefab_data, prefab)
        else
            null = true
            break
        end
    end
    if not null then
        
        save_data.data[prefab] = prefab_data
        fn_save()
    end
end

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local function ShowUI(data)
    local menu = h_util:GetControls().craftingmenu
    local icon = t_util:GetRecur(menu, "pinbar.open_menu_button.icon")
    if icon and icon.acui then
        icon.acui:Kill()
    end
    if not (icon and save_data.showui and type(data) == "table") then
        return
    end
    local ox, oy = icon:GetSize()
    icon.acui = icon:AddChild(Widget("autocook"))
    icon.acui:SetPosition(save_data.posx or 2 * ox, save_data.posy or 0)
    local space = 5
    local width = ox + space

    for slot = 1, #data do
        local sui = icon.acui:AddChild(Widget("autocook_slot" .. slot))
        sui:SetPosition((slot - 1) * (ox + space * 2), 0)
        sui.bg = sui:AddChild(Image("images/quagmire_recipebook.xml", "cookbook_known.tex"))
        sui.bg:SetSize(width, width)
        local prefab = data[slot]
        local xml, tex = h_util:GetPrefabAsset(prefab)
        if xml and tex then
            sui.img = sui:AddChild(Image(xml, tex))
            sui.img:SetSize(width, width)
        end
    end
    h_util:ActivateUIDraggable(icon.acui, function(pos)
        s_mana:SaveSettingLine(save_id, save_data, {
            posx = pos.x,
            posy = pos.y
        })
    end)
    icon.acui:SetHoverText(STRINGS.LMB .. "可拖拽 \n黏着鼠标请按Esc", {
        offset_y = -150,
        colour = UICOLOURS.GOLD,
        font_size = 18
    })
end

local function CheckIng(data, notcont)
    local ing_data = {}
    t_util:IPairs(data, function(prefab)
        ing_data[prefab] = ing_data[prefab] and ing_data[prefab] + 1 or 1
    end)
    local slots = p_util:GetSlotsFromAll() or {}
    local order_slots = {}
    t_util:Pairs(ing_data, function(prefab, size_ing)
        t_util:IPairs(slots, function(slot)
            if slot.item and slot.item.prefab == prefab then
                if notcont and slot.cont == notcont then
                    return
                end
                local size_slot = e_util:GetStackSize(slot.item)
                for i = size_ing, 0, -1 do
                    if size_slot <= 0 or size_ing <= 0 then
                        break
                    else
                        
                        size_slot = size_slot - 1
                        size_ing = size_ing - 1
                        table.insert(order_slots, slot)
                    end
                end
            end
        end)
    end)
    if #order_slots == #data then
        return order_slots
    end
end

local function ClearContainer(container, cont)
    while e_util:IsValid(cont) do
        local items = container:GetItems() or {}
        if next(items) then
            if t_util:GetElement(items, function(slot, item)
                local cont_cantake = p_util:CanTakeItem(item)
                if cont_cantake then
                    p_util:MoveItemFromAllOfSlot(slot, cont, cont_cantake)
                else
                    return true
                end
            end) then
                return false
            end
        else
            return true
        end
        d_util:Wait()
    end
end

local function Cook(prefab, data)
    if p_util:GetActiveItem() then
        return Say("物品已满")
    end
    
    local conts = e_util:FindEnts(nil, prefab, save_data.range_search, tags, nil, nil, nil, IsStewer)

    if conts[1] then
        
        local ret = CheckIng(data)
        if ret then
            
            local act, right
            local cont = t_util:IGetElement(conts, function(target)
                act, right = p_util:GetMouseActionSoft({"HARVEST", "RUMMAGE"}, target)
                if act then
                    if target._flag_next and act.action.id == "RUMMAGE" then
                        return
                    end
                    return target
                end
            end)
            if cont then
                if act.action.id == "RUMMAGE" then
                    local container = d_util:OpenContainer(cont)
                    if container then
                        if ClearContainer(container, cont) then
                            ret = CheckIng(data, cont)
                            if ret then
                                t_util:IPairs(ret, function(slot)
                                    p_util:MoveItemFromAllOfSlot(slot.slot, slot.cont, cont)
                                end)
                                StewerFn[prefab](cont, ThePlayer)
                                if #conts > 1 then
                                    cont._flag_next = true
                                    cont:DoTaskInTime(10 * FRAMES, function()
                                        cont._flag_next = nil
                                    end)
                                end
                            else
                                return Say("队列异常，烹饪中断")
                            end
                        else
                            return Say("无法清空烹饪锅")
                        end
                    else
                        return Say("无法打开烹饪锅")
                    end
                else
                    p_util:DoMouseAction(act, right)
                end
            else
                
            end
        else
            
            
            local act, right
            local pot = t_util:IGetElement(conts, function(target)
                act, right = p_util:GetMouseActionSoft({"HARVEST"}, target)
                return act and target
            end)
            if pot then
                p_util:DoMouseAction(act, right)
            else
                
                if not t_util:IGetElement(conts, function(target)
                    return not p_util:GetMouseActionSoft({"RUMMAGE"}, target)
                end) then
                    return true
                end
            end
        end
    else
        return Say("未找到烹饪锅")
    end
    d_util:Wait()
end

local function AutoCook(ent)
    local pusher = m_util:GetPusher()
    if not pusher then
        return
    end
    local btn = IsStewer(ent)
    
    if btn then
        if btn.validfn(ent) then
            btn.fn(ent, ThePlayer)
        end
    end
    if p_util:GetActiveItem() then
        p_util:ReturnActiveItem()
    end
    ent = type(ent) == "table" and ent or
              e_util:FindEnt(nil, nil, save_data.range_search, tags, nil, nil, nil, IsStewer)
    if ent and type(ent.prefab) == "string" then
        local data = save_data.data[ent.prefab]
        if data and #data > 0 then
            local mv = m_util:GetMovementPrediction()
            if mv then
                m_util:SetMovementPrediction()
            end
            ShowUI(data)
            Say("开始烹饪")
            pusher:RegNowTask(function()
                return Cook(ent.prefab, data)
            end, function()
                ShowUI(false)
                Say("烹饪结束")
                if mv then
                    m_util:SetMovementPrediction(mv)
                end
            end)
        else
            return Say("请先用 " .. ent.name .. " 烹饪一道菜")
        end
    else
        return Say("未找到烹饪锅")
    end
end

AddClassPostConstruct("screens/playerhud", function(self)
    
    local _OnMouseButton = self.OnMouseButton
    self.OnMouseButton = function(self, button, down, ...)
        if button == save_data.btn_conf and down and not TheInput:GetHUDEntityUnderMouse() then
            local ent = TheInput:GetWorldEntityUnderMouse()
            if IsStewer(ent) then
                AutoCook(ent)
            end
        end
        return _OnMouseButton(self, button, down, ...)
    end
    
    local _OpenContainer = self.OpenContainer
    self.OpenContainer = function(self, ent, ...)
        local ret = _OpenContainer(self, ent, ...)
        local btn_pot = IsStewer(ent)
        if btn_pot and not StewerFn[ent.prefab] then
            local _fn = btn_pot.fn
            StewerFn[ent.prefab] = _fn
            btn_pot.fn = function(ent, ...)
                SaveStewerData(ent)
                return _fn(ent, ...)
            end
        end
        return ret
    end
end)

m_util:AddBindConf(save_id, AutoCook, nil,
    {string_cook, "cookpot_tureen", STRINGS.LMB .. string_cook .. STRINGS.RMB .. string_cook .. "高级设置", true,
     AutoCook, m_util:AddBindShowScreen({
        title = string_cook,
        id = save_id,
        icon = {{
            id = "add",
            prefab = "mods",
            hover = "提示",
            fn = function()
                h_util:CreatePopupWithClose(nil, "该功能计划合并到智能锅中, 敬请期待。")
            end
        }},
        data = {{
            id = "bilibili1",
            prefab = "bilibili",
            type = "imgstr",
            label = "教程演示1",
            hover = "点击查看视频教程或功能演示",
            fn = function()
                VisitURL("https://www.bilibili.com/video/BV1h2CrB5E6f/", true)
            end
        }, {
            id = "bilibili2",
            prefab = "bilibili",
            type = "imgstr",
            label = "教程演示2",
            hover = "点击查看视频教程或功能演示",
            fn = function()
                VisitURL("https://www.bilibili.com/video/BV1czygBkENd/", true)
            end
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
            label = "鼠标绑定：",
            fn = fn_save("btn_conf"),
            hover = "设置相关绑定按键",
            default = fn_get,
            type = "radio",
            data = h_util:SetMouseSecond()
        }}
    })})
