local m_util = {
    keybinds = {},
    enable_showme = false,
    enable_insight = false,
    f_datas = {},
    screen_data = {
        ids = {},
        titles = {},
    },
    game_data = {},
}
local t_util = require "util/tableutil"
local c_util = require "util/calcutil"
local h_util = require "util/hudutil"
local s_mana = require "util/settingmanager"
local i_util = require "util/inpututil"
local e_util = require "util/entutil"
local PM = require "data/pinyin_char_map"
local TEMPLATES = require "widgets/redux/templates"
local ismodder = s_mana:GetSettingLine("i_am_modder", true).ismodder
local MID_CONF = "biubiu"


function m_util:Load(path, default_data)
    local data = {}
    TheSim:GetPersistentString(path, function(success, data_load)
        if success and string.len(data_load) > 0 then
            success, data_load = RunInSandbox(data_load)
            data = success and data_load or {}
        end
    end)
    t_util:Pairs(default_data or {}, function(k, v)
        if data[k] == nil then
            data[k] = v
        end
    end)
    return data
end

function m_util:Save(path, save_data)
    TheSim:SetPersistentString(path, DataDumper(save_data, nil, false), false)
end


local modname_table = t_util:IPairFilter(i_util:GetModsToLoad(), function(modname)
    local mod = KnownModIndex:GetModInfo(modname)
    return mod and mod.name and mod.version and mod.name .. mod.version
end)

function m_util:HasModName(modname)
    return t_util:GetElement(modname_table, function(_, name)
        return c_util:IsStrContains(name, modname)
    end)
end


local function getModName(modname)
    return type(modname) == "string" and modname or (Mod_ShroomMilk and Mod_ShroomMilk.Mod["春"].path)
end
function m_util:IsTurnOn(conf, modname)
    modname = getModName(modname)
    if not modname then
        return print("模组不存在！")
    end
    if type(conf) == "table" then
        return not t_util:IGetElement(conf, function(config)
            return not GetModConfigData(config, modname, true)
        end)
    else
        return GetModConfigData(conf, modname, true)
    end
end

function m_util:IsInBan(list)
    if type(list) == "table" then
        return t_util:IGetElement(list, function(modname)
            return self:HasModName(modname)
        end)
    else
        return self:HasModName(list)
    end
end






function m_util:AddBindConf(conf, fn, down, meta, modname)
    modname = getModName(modname)
    if not modname then
        return print("无法绑定！模组不存在！")
    end
    local key = GetModConfigData(conf, modname, true)
    local tp = type(key)
    local func = fn
    if tp == "number" then
        
        func = function()
            if m_util:InGame() and fn then
                fn()
            end
        end
        local press = down and "onkeydown" or "onkeyup"
        TheInput[press]:AddEventHandler(key, func)
        if down == "both" then
            TheInput.onkeyup:AddEventHandler(key, func)
        end
    elseif tp == "string" then
        
        if key == MID_CONF then
            m_util:AddBindIcon(unpack(meta))
        end
    else
        
    end
    local a_set = {
        conf = conf,
        modname = modname,
        fn = func,
        down = down,
        meta = meta,
        key = key
    }
    table.insert(m_util.keybinds, a_set)
    return function(presskey)
        return presskey == a_set.key
    end
end

function m_util:ReBindConf(key, conf, modname)
    local bdata = t_util:IGetElement(m_util.keybinds, function(setting)
        return setting.conf == conf and setting.modname == modname and setting
    end)
    if not bdata then
        return print("发生改绑异常！")
    end

    local function RemoveEp(ep)
        local handler = t_util:GetElement(TheInput[ep]:GetHandlersForEvent(bdata.key), function(handler)
            return handler.fn == bdata.fn and handler
        end)
        if handler then
            TheInput[ep]:RemoveHandler(handler)
        else
            print("未找到绑定动作")
        end
    end
    
    if bdata.key == MID_CONF then
        m_util:RemoveIcon(bdata.meta[1])
    elseif type(bdata.key) == "number" then
        RemoveEp(bdata.down and "onkeydown" or "onkeyup")
        if bdata.down == "both" then
            RemoveEp("onkeyup")
        end
    end
    if key == MID_CONF then
        m_util:AddBindIcon(unpack(bdata.meta))
    elseif type(key) == "number" then
        local press = bdata.down and "onkeydown" or "onkeyup"
        TheInput[press]:AddEventHandler(key, bdata.fn)
        if bdata.down == "both" then
            TheInput.onkeyup:AddEventHandler(key, bdata.fn)
        end
    end
    bdata.key = key
end


function m_util:LoadReBindData()
    local modsdata = {}
    return t_util:IPairFilter(m_util.keybinds, function(setting)
        local modname = getModName(setting.modname)
        if not modname then
            return
        end
        i_util:ClosePrint()
        modsdata[modname] = modsdata[modname] or KnownModIndex:LoadModConfigurationOptions(modname, true)
        i_util:OpenPrint()
        local moddata = modsdata[modname]
        return moddata and t_util:IGetElement(moddata, function(data)
            if data.name == setting.conf then
                local default = data.default
                local save = (type(data.saved) ~= "nil" and {data.saved} or {default})[1]
                local opts = type(data.options) == "table" and data.options or {}
                local data_default = t_util:IGetElement(opts, function(option)
                    return option.data == default and option.description
                end)
                local data_set = save == default and data_default or t_util:IGetElement(opts, function(option)
                    return option.data == save and option.description
                end)
                local allow_biubiu = t_util:IGetElement(opts, function(option)
                    return option.data == MID_CONF
                end)
                if data_set and data_default then
                    local id = setting.conf .. getModName(setting.modname)
                    return {
                        id = id,
                        label = data.label .. "：",
                        hover = data.hover,
                        default = tostring(data_set),
                        type = "textbtn",
                        fn = function(text, btns)
                            h_util:CreatePressScreen(data.label, text, data_default, allow_biubiu, opts,
                                function(value, text)
                                    local function SaveAndLoad()
                                        
                                        local ret = m_util:SaveModOneConfig(setting.conf, value, modname)
                                        
                                        m_util:ReBindConf(ret, setting.conf, setting.modname)
                                        
                                        return ret
                                    end
                                    
                                    local rep_label = type(value) == "number" and
                                                          t_util:IGetElement(m_util.keybinds, function(set_data)
                                            if set_data.key == value and
                                                not (set_data.conf == setting.conf and set_data.modname ==
                                                    setting.modname) then
                                                local modname = getModName(set_data.modname)
                                                if not modname then
                                                    return
                                                end
                                                local moddata = modsdata[modname] or {}
                                                return t_util:IGetElement(moddata, function(data)
                                                    return data.name == set_data.conf and data.label
                                                end)
                                            end
                                        end)
                                    local ret = SaveAndLoad()

                                    if rep_label then
                                        if value == ret then
                                            i_util:DoTaskInTime(0.3, function()
                                                h_util:CreatePopupWithClose("迟到的提示",
                                                    "你设置的按键与功能【" .. rep_label ..
                                                        "】冲突了, 但还是成功设置上了", {{
                                                        text = "我知道了"
                                                    }})
                                            end)
                                        end
                                        btns[id].uiSwitch("按键冲突 " .. text)
                                    else
                                        btns[id].uiSwitch(text)
                                    end
                                end)
                        end
                    }
                end
            end
        end)
    end)
end



function m_util:SaveModOneConfig(c_name, c_value, modname)
    modname = getModName(modname)
    if not modname then
        return print("模组不存在！无法写入！")
    end
    local ret
    i_util:ClosePrint()
    local config = KnownModIndex:LoadModConfigurationOptions(modname, true) or {}
    local settings = t_util:IPairFilter(config, function(conf_data)
        local name, value, default = conf_data.name, conf_data.saved, conf_data.default
        if name then
            if name == c_name then
                local opts = type(conf_data.options) == "table" and conf_data.options or {}

                if type(c_value) == "nil" then
                    value = default
                elseif t_util:IGetElement(opts, function(opt)
                    return opt.data == c_value
                end) then
                    value = c_value
                end
                ret = value
            end
            return {
                name = name,
                saved = value
            }
        end
    end)
    KnownModIndex:SaveConfigurationOptions(function()
    end, modname, settings, true)
    i_util:OpenPrint()
    return ret
end

function m_util:IsTyping()
    return TheFrontEnd and (t_util:GetRecur(TheFrontEnd:GetFocusWidget(), "inst.TextEditWidget") or TheFrontEnd.textProcessorWidget)
end
function m_util:InGame()
    return ThePlayer and ThePlayer.components.hx_pusher and not self:IsTyping() and ThePlayer.prefab
end
function m_util:InHUD()
    return ThePlayer and ThePlayer.HUD==h_util:GetActiveScreen() and not self:IsTyping() and ThePlayer.HUD
end

function m_util:GetMovementPrediction()
    return Profile:GetMovementPredictionEnabled()
end
function m_util:SetMovementPrediction(enable)
    enable = enable and true or false
    if ThePlayer then
        ThePlayer:EnableMovementPrediction(enable)
    end
    Profile:SetMovementPredictionEnabled(enable)
end

local is_lava, is_quag = TheNet:GetServerGameMode() == "lavaarena", TheNet:GetServerGameMode() == "quagmire"
function m_util:IsLava()
    return is_lava
end
function m_util:IsQuag()
    return is_quag
end

local is_server = TheNet:IsDedicated() or is_lava or (TheNet:GetIsServer() and TheNet:GetServerIsDedicated())
function m_util:IsServer()
    return is_server
end

function m_util:IsHost()
    return TheWorld and TheWorld.ismastersim
end

function m_util:IsBata()
    return BRANCH ~= "release" and APP_VERSION;
end
function m_util:IsAdmin()
    return TheNet and TheNet:GetIsServerAdmin()
end
function m_util:IsOffline()
    return TheFrontEnd:GetIsOfflineMode() or not TheNet:IsOnlineMode()
end

local ishuxi = TheSim:GetUsersName() == "466540397@steam"
function m_util:IsHuxi()
    return ishuxi or ismodder 
end
function m_util:IsMilker()
    return ishuxi
end

local icons = {}
local needrefresh




function m_util:AddBindIcon(name, icondata, hover, closewindow, func_left, func_right, priority)
    if type(name) == "string" and icons[name] then
        return print(name, "按钮注册失败！已经被注册过了")
    else
        if type(hover) == "string" and type(func_left) == "function" then
            local icon = {
                text = hover,
                func_left = func_left,
                close = closewindow and true,
                func_right = type(func_right) == "function" and func_right,
                priority = type(priority) == "number" and priority or 0,
                imgdata = icondata
            }
            local name = type(name) == "table" and name.name or name
            if type(name) ~= "string" then
                return print("图标名字不合法！")
            else
                icon.name = name
                icons[name] = icon
                self:RefreshIcon(true)
            end
        else
            return print("图标提示或绑定操作不合法！")
        end
    end
end














local screen
function m_util:AddBindShowScreen(conf, title, icon, hover, screen_data, modname, priority)
    local function ScreenFn()
        if "ShowScreen" == h_util:GetActiveScreen().name and not screen_data.dontpop then
            TheFrontEnd:PopScreen(screen)
        else
            screen = require("screens/huxi/showscreen")(screen_data)
            TheFrontEnd:PushScreen(screen)
        end
    end
    local tp_conf, tp_screen = type(conf), type(screen_data)
    if tp_conf == "table" then
        screen_data = conf
        return ScreenFn
    elseif tp_conf == "string" then
        if tp_screen == "table" then
            m_util:AddBindConf(conf, ScreenFn, nil, {title, icon, hover, true, ScreenFn, nil, priority}, modname)
        elseif tp_screen == "function" then
            return m_util:AddBindConf(conf, screen_data, nil, {title, icon, hover, true, screen_data, nil, priority},
                modname)
        end
    end
    self:RefreshIcon(true)
end


function m_util:HookShowScreenData(screen_data)
    local id, title = screen_data.id, screen_data.title
    local fns_id = id and self.screen_data.ids[id]
    local fns_title = title and self.screen_data.titles[title]
    if fns_id then
        t_util:IPairs(fns_id, function(fn)
            fn(screen_data.data, screen_data)
        end)
    end
    if fns_title then
        t_util:IPairs(fns_title, function(fn)
            fn(screen_data.data, screen_data)
        end)
    end
    return screen_data
end

function m_util:BindShowScreenID(id, fn)
    if id and type(fn) == "function" then
        if self.screen_data.ids[id] then
            table.insert(self.screen_data.ids[id], fn)
        else
            self.screen_data.ids[id] = {fn}
        end
    end
end
function m_util:BindShowScreenTitle(title, fn)
    if title and type(fn) == "function" then
        if self.screen_data.titles[title] then
            table.insert(self.screen_data.titles[title], fn)
        else
            self.screen_data.titles[title] = {fn}
        end
    end
end


function m_util:PopShowScreen()
    local screen = h_util:GetShowScreen()
    if screen then
        TheFrontEnd:PopScreen(screen)
    end
end

function m_util:RefreshIcon(state)
    needrefresh = state
end

function m_util:GetRefresh()
    return needrefresh
end

function m_util:RemoveIcon(name)
    if icons[name] then
        icons[name] = nil
        self:RefreshIcon(true)
        return true
    end
end

function m_util:GetIcons()
    return icons
end


function m_util:print(...)
    if not self:IsHuxi() then
        return
    end
    print(os.date("%I:%M:%S %p", os.time()), unpack(t_util:IPairToIPair({...}, function(v)
        return tonumber(v) and math.floor(v) ~= v and string.format("%.2f", v) or v
    end)))
end


local ModPrefabs, LoadPrefabs = {}, {}
function m_util:IsModPrefab(prefab)
    if not LoadPrefabs[prefab] then
        ModPrefabs[prefab] = t_util:IGetElement(i_util:GetModsToLoad(), function(name)
            local mod = ModManager:GetMod(name)
            local prefabs = mod and mod.Prefabs or {}
            return prefabs[prefab] and mod 
        end)
        LoadPrefabs[prefab] = true
    end
    return ModPrefabs[prefab]
end

function m_util:EnableShowme()
    return m_util.enable_showme
end
function m_util:EnableInsight()
    return m_util.enable_insight
end

function m_util:QueryShowme(target)
    local guid = target and target.GUID
    if not guid then
        return
    end
    SendModRPCToServer(MOD_RPC.ShowMeSHint.Hint, guid, target)
    
    local data_hint = t_util:GetRecur(ThePlayer, "player_classified.showme_hint2")
    if not data_hint then
        return
    end

    
    local function UnpackData(str, div)
        local pos, arr = 0, {}
        
        for st, sp in function()
            return string.find(str, div, pos, true)
        end do
            table.insert(arr, string.sub(str, pos, st - 1))
            pos = sp + 1
        end
        table.insert(arr, string.sub(str, pos))
        return arr
    end

    local i = string.find(data_hint, ';', 1, true)
    if not i then
        return
    end
    local guid_get = tonumber(data_hint:sub(1, i - 1))
    if guid_get ~= guid then
        return
    end
    local str = data_hint:sub(i + 1)
    if not str or str == "" then
        return
    end
    str = UnpackData(str, "\2")
    local data_pack = {}
    for i, v in ipairs(str) do
        if v ~= "" then
            local param_str = v:sub(2)
            table.insert(data_pack, UnpackData(param_str, ","))
        end
    end
    local ret = {}
    t_util:IPairs(data_pack, function(data)
        if type(data) == "table" then
            t_util:IPairs(data, function(i)
                table.insert(ret, tonumber(i))
            end)
        end
    end)
    return ret
end



function m_util:GetSaver()
    return TheWorld and TheWorld.components.hx_saver
end



function m_util:GetPusher()
    return ThePlayer and ThePlayer.components.hx_pusher
end



function m_util:AddWatcher(inst)
    local watcher = inst.components.hx_watcher
    return watcher or inst:AddComponent("hx_watcher")
end


function m_util:AddGameData(cate, id, data)
    if not (cate and id) then return end
    local cate_data = self.game_data[cate]
    if cate_data then
        cate_data[id] = data
    else
        self.game_data[cate] = {[id] = data}
    end
end

function m_util:GetGameData(cate)
    return cate and self.game_data[cate]
end



function m_util:AddRightMouseData(id, label, hover, default, fn, meta)
    self:AddGameData("RIGHT", id, {
        id = id,
        label = label,
        hover = hover,
        default = default,
        fn = fn,
        screen_data = meta and meta.screen_data,
        priority = meta and meta.priority,
    })
end


function m_util:AddNoteData(id, title, width, height, content, meta)
    self:AddGameData("NOTE", id, 
    t_util:MergeMap({
        id = id,
        title = title,
        content = content,
        width = width,
        height = height,
    }, meta or {}))
end

function m_util:GetData(name)
    local r_data = t_util:PairToIPair(self:GetGameData(name) or {}, function(id, data)
        return data
    end)
    t_util:SortIPair(r_data)
    return r_data
end

function m_util:IsMovePressing()
    for control = CONTROL_MOVE_UP, CONTROL_MOVE_RIGHT do
        if TheInput:IsControlPressed(control) then
            return true
        end
    end
end

function m_util:RemoveHandler(ipt, eventname, func)
    local handler = ipt and eventname and t_util:GetElement(ipt:GetHandlersForEvent(eventname), function(handler)
        return handler.fn == func and handler
    end)
    if handler then
        ipt:RemoveHandler(handler)
    end
end


function m_util:AddKeyBind(func, keycode, up)
    local press = up and "onkeyup" or "onkeydown"
    local ipt = TheInput[press]
    local id = self.f_datas[func]
    if id then
        self:RemoveHandler(ipt, id, func)
        m_util.f_datas[func] = nil
    end
    if not keycode then
        return
    end
    ipt:AddEventHandler(keycode, func)
    self.f_datas[func] = keycode
end



function m_util:PushPrefabScreen(info)
    local info = c_util:FormatDefault(info, "table")
    local function fn_setprefab(prefab, ui, grid, context)
        if not (h_util:IsValid(ui) and ui.detail) then return end
        context.prefab = context.prefab ~= prefab and prefab
        if ui.grid then ui.grid:RefreshView() end
        if context.prefab then
            ui.detail.icon_show.SetPrefabIcon({prefab = prefab})
            local name = e_util:GetPrefabName(prefab)
            name = name == e_util.NullName and "" or name
            ui.detail.text_show:SetString(name.."\n"..prefab)
            
            ui.detail.btn_ok:SetOnClick(function()
                if info.fn_btnok then
                    info.fn_btnok(prefab, ui)
                end
                self:PopShowScreen()
            end)
            ui.detail.btn_ok:Enable()
        else
            ui.detail.icon_show.SetPrefabIcon({prefab = "cookbook_missing"})
            ui.detail.text_show:SetString("")
            ui.detail.btn_ok:Disable()
        end
    end
    local function GetPrefabsData(prefabs)
        if not prefabs then
            local prefab_skins = {}
            t_util:Pairs(PREFAB_SKINS or {}, function(_, skindata)
                t_util:IPairs(skindata, function(skinname)
                    prefab_skins[skinname] = true
                end)
            end)
            prefabs = t_util:PairToIPair(Prefabs or {}, function(prefab, data)
                return not prefab_skins[prefab] and not(prefab:find("_spawner") or prefab:find("_blueprint"))  and prefab
            end)
        end
        table.sort(prefabs, function(a, b)
            return a < b
        end)
        return t_util:IPairFilter(prefabs, function(prefab)
            local xml, tex, name = h_util:GetPrefabAsset(prefab)
            return xml and {
                xml = xml,
                tex = tex,
                name = name,
                prefab = prefab,
                hover = name == e_util.NullName and prefab or name.."\n"..prefab
            }
        end)
    end
    local function fn_edited()
        local ui = h_util:GetLines()
        local textedit = t_util:GetRecur(ui, "editline.textedit.textbox")
        if not textedit then return end
        local text = c_util:TrimString(textedit:GetString())
        local p_data = GetPrefabsData()
        if text == "" then
            ui.grid:SetItemsData(p_data)
        else
            ui.grid:SetItemsData(t_util:IPairFilter(p_data, function(data)
                if data.prefab:rfind_plain(text) then
                    return data
                else
                    if data.name ~= e_util.NullName and PM:Find(data.name, text) then
                        return data
                    end
                end
            end))
        end
    end
    local function fn_clear()
        local ui = h_util:GetLines()
        local textedit = t_util:GetRecur(ui, "editline.textedit.textbox")
        if textedit then
            textedit:SetString("")
            ui.grid:SetItemsData(GetPrefabsData())
        end
    end
    local function fn_loadui(ui)
        ui.editline:SetPosition(-201, 112)
        ui.detail:SetPosition(233, 70)
        ui.detail:SetScale(.9)

        ui.detail.btn_write.image:SetTint(1, 1, .5, 1)
        ui.detail.btn_write:SetPosition(0, -220)
        ui.detail.btn_write:SetHoverText(info.hover_btnwrite or "手动输入左边找不到的 物品代码", {offset_y = 60})
        ui.detail.btn_write:SetOnClick(function()
            h_util:CreateWriteWithClose("输入物品代码：", {
                text = "确认",
                cb = function(prefab)
                    info.fn_btnok(prefab, ui)
                    self:PopShowScreen()
                    
                    
                end
            })
        end)

        ui.detail.btn_ok.image:SetTint(.4, 1, .4, 1)
        ui.detail.btn_ok:SetPosition(0, -295)
        ui.detail.btn_ok:SetHoverText(info.hover_btnok or "就决定是你了！", {offset_y = 60})

        ui.grid:SetItemsData(GetPrefabsData())
        fn_setprefab(t_util:GetPrefab(), ui, ui.grid, {})
    end
    self:AddBindShowScreen{
        title = info.text_title or "物品选择器",
        id = info.id or "prefab_selected",
        data = {},
        type = "player",
        data_create = {
            {
                id = "grid",
                fn = function()
                    return h_util:BuildGrid_PrefabButton{
                        context = info.context,
                        fn_sel = fn_setprefab,
                    }
                end
            },{
                id = "editline",
            },{
                id = "textedit",
                pid = "editline",
                fn = function()
                    return h_util:CreateTextEdit({width = 320, height = 60, hover = "输入 物品的名称 或 代码 或 拼音", fn = fn_edited})
                end
            },{
                id = "btn_clear",
                pid = "editline",
                fn = function()
                    return h_util:CreateImageButton({prefab = "delete", hover = "清理结果", hover_meta = {offset_y = 50}, pos = {190}, size = 60, fn = fn_clear})
                end,
            },{
                id = "btn_filter", 
                pid = "editline",
                fn = function()
                    return h_util:CreateImageButton({xml = HUD_ATLAS, tex = "magnifying_glass_off.tex", hover = "点击搜索", hover_meta = {offset_y = 50}, pos = {250}, size = 60, fn = fn_edited})
                end,
            },{
                id = "detail",
                fn = function()
                    return h_util:BuildGrid_PrefabDetail()
                end
            },{
                id = "btn_ok",
                pid = "detail",
                fn = function()
                    return TEMPLATES.StandardButton(nil, info.text_btnok or "确认选择", {250, 80})
                end
            },{
                id = "btn_write",
                pid = "detail",
                fn = function()
                    return TEMPLATES.StandardButton(nil, info.text_btnwrite or "手动输入", {250, 80})
                end
            },
        },
        fn_line = fn_loadui,
        dontpop = true,
        title_help = "功能联动",
        help = m_util:HasModName("群鸟绘卷·夏") and "宣告物品后，\n这里就会直接选中刚刚宣告的物品。" or "尚未启用【绘卷·夏】，\n无法使用快速选择！"
    }()
end


function m_util:ExportModsInfo()
    local filename = "___(^o^)___.txt"
    local str = "\n"..i_util:GetModsInfo().."\n\n\n\n"..i_util:GetModsClash()
    TheSim:SetPersistentString("../"..filename, str)
    h_util:CreatePopupWithClose("模组信息已导出", "请打开 "..filename.." 查看", {{
        text = h_util.ok,
        cb = function()
            TheSim:OpenDocumentsFolder()
        end}})
end


function m_util:ExportEntsInfo()
    local filename = "@@@ 50 @@@.txt"
    local str = "\n"..i_util:GetEntsInfo()
    TheSim:SetPersistentString("../"..filename, str)
    h_util:CreatePopupWithClose("实体信息已导出", "请打开 "..filename.." 查看", {{
        text = h_util.ok,
        cb = function()
            TheSim:OpenDocumentsFolder()
        end}})
end









function m_util:FuncListRemove(save_data, id_list, fn_save, fn_title, fn_body, fn_img_hover, fn_mod_hover)
    return function()
        return t_util:IPairToIPair(save_data[id_list], function(prefab)
            local name = e_util:GetPrefabName(prefab)
            name = name == e_util.NullName and prefab or name
            local data = {
                id = prefab, 
                fn = function()
                    h_util:CreatePopupWithClose(fn_title(name), type(fn_body)=="string" and fn_body or fn_body(name), {
                        {
                            text = h_util.no
                        },{
                            text = "确定移除",
                            cb = function()
                                t_util:Sub(save_data[id_list], prefab)
                                fn_save()
                            end
                        }
                    })
                end
            }
            local str = c_util:TruncateChineseString(name, 10)
            if h_util:GetPrefabAsset(prefab) then
                data.type = "imgstr"
                data.label = str
                data.hover = fn_img_hover(name, prefab)
                data.prefab = prefab
            else
                data.type = "textbtn"
                data.default = str
                data.label = "模组物品："
                data.hover = type(fn_mod_hover)=="string" and fn_mod_hover or fn_mod_hover(name, prefab)
            end
            return data
        end)
    end
end




function m_util:FuncListReset(save_data, default_data, fn_save, str_body, id_list, fn_refresh)
    return function()
        h_util:CreatePopupWithClose("警告", str_body.."\n一旦确认不可撤销！", {
            {
                text = h_util.no,
            },{
                text = h_util.yes,
                cb = function()
                    
                    save_data[id_list] = {}
                    t_util:EasyCopy(save_data[id_list], default_data[id_list])
                    fn_save()
                    h_util:PlaySound("learn_map")
                    if type(fn_refresh)=="function" then
                        fn_refresh()
                    end
                end
            }
        })
    end
end

function m_util:FuncListAdd(save_data, fn_save, id_list, title, name)
    return function()
        m_util:PushPrefabScreen{
            text_title = "选择要"..title.."的"..name,
            text_btnok = "添加"..name,
            hover_btnok = "添加该"..name.."到"..title.."..的列表",
            fn_btnok = function(prefab)
                if table.contains(save_data[id_list] or {}, prefab) then
                    h_util:CreatePopupWithClose("重复添加", "该"..name.."已经在"..title.."列表中，\n还请添加别的"..name.."。")
                else
                    t_util:Add(save_data[id_list] or {}, prefab, true)
                    fn_save()
                end
            end,
        }
    end
end


function m_util:DebugRequire(path)
    if not path then return print("路径不存在！") end
    package.loaded[path] = nil
    local success, ret = pcall(require, path)
    if ret then
        return ret
    else
        print(ret)
    end
end





function m_util:RegisterScreenInGame(screen_name)
    i_util:ObsoletePrint()
end

function m_util:ClosePrint()
    i_util:ObsoletePrint()
    i_util:ClosePrint()
end
function m_util:OpenPrint()
    i_util:ObsoletePrint()
    i_util:OpenPrint()
end



return m_util
