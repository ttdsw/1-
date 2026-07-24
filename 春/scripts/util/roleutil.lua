




local t_util = require "util/tableutil"
local b_util = require "util/bindutil"
local h_util = require "util/hudutil"
local m_util = require "util/modutil"
local p_util = require "util/playerutil"
local PopupDialogScreen = require "screens/redux/popupdialog"
local r_util = {
    f_datas = {}, 
    
}
local function RemoveHandler(ipt, eventname, func)
    local handler = ipt and eventname and t_util:GetElement(ipt:GetHandlersForEvent(eventname), function(handler)
        return handler.fn == func and handler
    end)
    if handler then
        ipt:RemoveHandler(handler)
    end
end


function r_util:BindMouseFunc(func, btn)
    local omb = "onmousebutton"
    local ipt = TheInput[omb]
    RemoveHandler(ipt, omb, func)
    if not btn then return end
    ipt:AddEventHandler(omb, func)
end



function r_util:BindMoveFunc(func, bind)
    local ipt = TheInput.position
    RemoveHandler(ipt, "move", func)
    if not bind then return end
    ipt:AddEventHandler("move", func)
end


function r_util:BindKeyFunc(func, id, up)
    local press = up and "onkeyup" or "onkeydown"
    local ipt = TheInput[press]
    local f_data = r_util.f_datas[func] 
    if f_data then
        RemoveHandler(ipt, b_util:GetKeyCode(f_data.id), f_data.fn)
        r_util.f_datas[func] = nil
    end
    local key_code = b_util:GetKeyCode(id)
    if not key_code then return end
    local fn = b_util:PackKeyFunc(function()
        if not m_util:InGame() then return end
        func()
    end, id)
    ipt:AddEventHandler(key_code, fn)
    r_util.f_datas[func] = {
        id = id,
        fn = fn,
    }
end


function r_util:GetLabelShow(fn_get)
    return function(id)
        return b_util:GetShowLabel(fn_get(id))
    end
end

function r_util:GetLabelSet(fn_set)
    return function(id, title)
        return function(str_now, btns)
            self:CreatePressScreen(title, str_now, function(value)
                btns[id].uiSwitch(b_util:GetShowLabel(value))
                fn_set(id)(value)
            end) 
        end
    end
end

local function PopFunc()
    TheFrontEnd:PopScreen()
end
function r_util:CreatePressScreen(title, str_now, callback)
    local format_string = "请按下键盘按键为【%s】设置绑定!\n(支持Ctrl/Shift/Alt等组合键) \n\n 当前绑定：[%s]"
    local body_text = format_string:format(title, str_now)
    local btns = {
        {text = STRINGS.UI.CONTROLSSCREEN.CANCEL, cb = PopFunc},
        {text = "注销绑定", cb = function()
            callback(false)
            PopFunc()
        end}
    }
    local popup = PopupDialogScreen(title, body_text, btns)
    popup.OnRawKey = function(_, key, down)
        if down then return end
        local value = b_util:GetKeyValue(key)
        if value then
            h_util:PlaySound("click_move")
            callback(value)
            PopFunc()
        elseif not b_util:IsPressCSA() then
            h_util:PlaySound("click_negative")
        end
    end
    TheFrontEnd:PushScreen(popup)
end



function r_util:SpellBook(book)
    local spell = t_util:GetRecur(book or {}, "components.spellbook")
    local hud = ThePlayer.HUD
    if not (spell and hud) then return end
    if hud:IsSpellWheelOpen() then
        hud:CloseSpellWheel()
    else
        spell:OpenSpellBook(ThePlayer)
    end
end


function r_util:PackSpellBook(num_spell, GetBook, save_data, default_data)
    return t_util:BuildNumInsert(1, num_spell, function(i)
        return function()
            local book = GetBook()
            local spell = book and book.components.spellbook
            if not spell then return end
            spell:SelectSpell(i)
            if save_data.quick == default_data.quick then
                local pos = TheInput:GetWorldPosition()
                local act = BufferedAction(ThePlayer, nil, ACTIONS.CASTAOE, book, pos)
                p_util:DoAction(act, RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true, 10, nil, nil, nil, nil, book, i)
            else
                local ex = spell.items[i] and spell.items[i].execute
                if ex then
                    ex(book)
                end
            end
        end
    end)
end


function r_util:PackSpellFromLabel(GetBook, labels, save_data, default_data, toself)
    return function()
        local book = GetBook()
        local spell = book and book.components.spellbook
        local items = t_util:GetRecur(book, "components.spellbook.items")
        if not items then return end
        labels = type(labels) == "table" and labels or {labels}
        local id = t_util:GetElement(items, function(id, data)
            return table.contains(labels, data.label) and id
        end)
        if not id then return end
        spell:SelectSpell(id)
        if toself or save_data.quick ~= default_data.quick then
            local ex = spell.items[id] and spell.items[id].execute
            if ex then
                ex(book)
            end
        else
            local pos = TheInput:GetWorldPosition()
            local act = BufferedAction(ThePlayer, nil, ACTIONS.CASTAOE, book, pos)
            p_util:DoAction(act, RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true, 10, nil, nil, nil, nil, book, id)
        end
    end
end

function r_util:PackCheckRole(player_prefab, save_data)
    return function ()
        if not ThePlayer then return end
        if ThePlayer.prefab == player_prefab then
            return true
        end
        return not save_data.only
    end
end


function r_util:InitPack(save_data, fn_get, fn_save, fn_press, key_id)
    self:BindKeyFunc(fn_press, save_data[key_id])
    local fn_show = r_util:GetLabelShow(fn_get)
    local fn_text = r_util:GetLabelSet(function(id)
        return function(val)
            fn_save(id)(val)
            r_util:BindKeyFunc(fn_press)
            r_util:BindKeyFunc(fn_press, save_data[key_id])
        end
    end)
    return fn_show, fn_text
end

function r_util:ScreenPack(save_data, fn_get, fn_save, fn_press, key_id, title)
    local fn_show, fn_text = self:InitPack(save_data, fn_get, fn_save, fn_press, key_id)
    return {
        id = key_id,
        label = "绑定按键：",
        hover = "【"..title.."】的绑定按键",
        type = "textbtn",
        default = fn_show,
        fn = fn_text(key_id, title),
    }
end


function r_util:InGame()
    print("群鸟绘卷：您使用了一个即将废弃的接口，请改用m_util:InGame()")
    return m_util:InGame()
end

return r_util