local t_util = require("util/tableutil")
local i_util = {
    world_func_in = {},
    data_func_load = {},
    leftclick_func = {},
    rightclick_func = {},
    midclick_func = {},
    hoverer_func_in = {},
    hoverer_func_in2 = {},
    server_rpc_func = {},
    server_rpc_lfunc = {},
    player_func_in = {},
    player_func_out = {},
    ltor_push_func = {},
    ltor_goto_func = {},
    prefabs_hook_end = {},
    listenuse_pre = {},
    listenuse_end = {},
    listenwith_pre = {},
    listenwith_end = {},
    NullFunction = function()end,
    names_loadmod = nil,
}


function i_util:ExRemote(str)
    if not TheNet:GetIsServerAdmin() then
        return
    end
    if TheNet:GetIsClient() then
        local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
        TheNet:SendRemoteExecute(str, x, z)
    else
        ExecuteConsoleCommand(str)
    end
end


function i_util:GoTo(x, z)
    if type(x) ~= "number" and type(z) ~= "number" then
        return print("参数非法！x =", x, "z =", z)
    end
    local fnstr = "ThePlayer.Transform:SetPosition(" .. x .. ", 0, " .. z .. ")"
    self:ExRemote(fnstr)
end



function i_util:AddPlayerActivatedFunc(func)
    if type(func) == "function" then
        table.insert(i_util.player_func_in, func)
    end
end


function i_util:AddPlayerDeactivatedFunc(func)
    if type(func) == "function" then
        table.insert(i_util.player_func_out, func)
    end
end


function i_util:AddSessionLoadFunc(func)
    if type(func) == "function" then
        table.insert(i_util.data_func_load, func)
    end
end



function i_util:AddWorldActivatedFunc(func)
    if type(func) == "function" then
        table.insert(i_util.world_func_in, func)
    end
end


function i_util:DoTaskInTime(time, ...)
    return TheGlobalInstance:DoStaticTaskInTime(time, ...)
end


function i_util:DoPeriodicTask(time, func)
    func()
    return TheGlobalInstance:DoPeriodicTask(time, func)
end





function i_util:AddRightClickFunc(func)
    if type(func) == "function" then
        table.insert(i_util.rightclick_func, func)
    end
end


function i_util:AddLeftClickFunc(func)
    if type(func) == "function" then
        table.insert(i_util.leftclick_func, func)
    end
end


function i_util:AddMiddleClickFunc(func)
    if type(func) == "function" then
        table.insert(i_util.midclick_func, func)
    end
end




function i_util:AddHoverOverFunc(func)
    if type(func) == "function" then
        table.insert(i_util.hoverer_func_in, func)
    end
end
function i_util:AddHoverOverFunc2(func)
    if type(func) == "function" then
        table.insert(i_util.hoverer_func_in2, func)
    end
end




function i_util:AddServerRPCFunc(func)
    if type(func) == "function" then
        table.insert(i_util.server_rpc_func, func)
    end
end



function i_util:AddServerLongRPCFunc(func)
    if type(func) == "function" then
        table.insert(i_util.server_rpc_lfunc, func)
    end
end






function i_util:AddPushActionFunc(func)
    if type(func) == "function" then
        table.insert(i_util.ltor_push_func, func)
    end
end




function i_util:AddGoToActionFunc(func)
    if type(func) == "function" then
        table.insert(i_util.ltor_goto_func, func)
    end
end








function i_util:AddPrefabsHook(data)
    if type(data) == "table" then
        if data.prefabs and data.id and data.time then
            table.insert(i_util.prefabs_hook_end, data)
        end
    end
end


function i_util:AddFoodActivatedFunc(func)
    self:AddInvItemUsePre("eat", func)
end
function i_util:AddFoodDeactivatedFunc(func)
    self:AddInvItemUseEnd("eat", func)
end




function i_util:AddInvItemUsePre(act_id, func)
    if type(func) == "function" then
        local act = ACTIONS[tostring(act_id):upper()]
        local code = act and act.code
        if code then
            if i_util.listenuse_pre[code] then
                table.insert(i_util.listenuse_pre[code], func)
            else
                i_util.listenuse_pre[code] = {func}
            end
        end
    end
end




function i_util:AddInvItemUseEnd(act_id, func_do, func_get)
    if type(func_do) == "function" then
        local act = ACTIONS[tostring(act_id):upper()]
        local code = act and act.code
        if code then
            local data = {
                func_get = type(func_get) == "function" and func_get,
                func_do = func_do,
            }
            if i_util.listenuse_end[code] then
                table.insert(i_util.listenuse_end[code], data)
            else
                i_util.listenuse_end[code] = {data}
            end
        end
    end
end


function i_util:AddInvItemWithPre(act_id, func)
    if type(func) == "function" then
        local act = ACTIONS[tostring(act_id):upper()]
        local code = act and act.code
        if code then
            if i_util.listenwith_pre[code] then
                table.insert(i_util.listenwith_pre[code], func)
            else
                i_util.listenwith_pre[code] = {func}
            end
        end
    end
end




function i_util:AddInvItemWithEnd(act_id, func_do, func_get)
    if type(func_do) == "function" then
        local act = ACTIONS[tostring(act_id):upper()]
        local code = act and act.code
        if code then
            local data = {
                func_get = type(func_get) == "function" and func_get,
                func_do = func_do,
            }
            if i_util.listenwith_end[code] then
                table.insert(i_util.listenwith_end[code], data)
            else
                i_util.listenwith_end[code] = {data}
            end
        end
    end
end


function i_util:LoadLayout(path)
    if kleifileexists("scripts/" .. path .. ".lua") then
        local data = require("map/static_layout").Get(path)
        return data.ground and data
    end
end


function i_util:GetModsToLoad()
    if not self.names_loadmod then
        self.names_loadmod = {}
        self:ClosePrint()
        t_util:IPairs(KnownModIndex:GetModsToLoad(), function(modname)
            table.insert(self.names_loadmod, modname)
        end)
        self:OpenPrint()
    end
    return self.names_loadmod
end

function i_util:GetModsCS()
    local mods_c, mods_s = {}, {}
    self:ClosePrint()
    t_util:IPairs(self:GetModsToLoad(), function(modname)
        local mod = ModManager:GetMod(modname) or {}
        local modinfo = mod.modinfo or {}
        local name = modinfo.name or modname
        if not name or name:find("风华") then return end

        local config = KnownModIndex:LoadModConfigurationOptions(modname, modinfo.client_only_mod and true or false)
        local settings = t_util:IPairFilter(config or {}, function(conf_data)
            local name, value, default, label, des = conf_data.name, conf_data.saved, conf_data.default, conf_data.label, conf_data.description
            return name and value~=nil and value ~= default and {
                name = tostring(name),
                value = tostring(value),
                label = tostring(label),
                
            }
        end)

        table.insert(modinfo.client_only_mod and mods_c or mods_s, {
            name = name:gsub("\n", ""),
            version = modinfo.version or "未知",
            path = modname,
            settings = settings,
            author = tostring(modinfo.author),
        })
    end)
    self:OpenPrint()
    return mods_c, mods_s
end

function i_util:GetGameInfo()
    local str = "\n【游戏信息】\n"
    str = str..os.date("日志生成时间： %Y年%m月%d日 %H:%M:%S ").."\n"
    local time_active = math.floor(TheSim:GetRealTime()/1000)
    str = str.."游戏运行时间："..time_active.."秒\n"
    local num = TheSim:GetNumberOfEntities()
    str = str.."游戏运行实体数："..num.."\n"
    local fps = math.ceil(TheSim:GetFPS())
    str = str.."游戏运行FPS："..fps.."\n"
    
    if ThePlayer then
        str = str.."\n\n【玩家信息】\n"
        str = str.."玩家昵称："..ThePlayer.name.."\n"
        str = str.."玩家ID："..(ThePlayer.userid or "未能获取").."\n"
        str = str.."当前角色："..ThePlayer.prefab.."\n"
    end

    return str
end

function i_util:GetModsInfo()
    local str = i_util:GetGameInfo()
    local mods_c, mods_s = self:GetModsCS()
    local function show(mod)
        str = str..mod.name.."        版本："..mod.version.."        文件夹："..mod.path.."\n"
    end
    str = str.."\n\n【客户端模组】 "..#mods_c.."个\n"
    t_util:IPairs(mods_c, show)

    str = str.."\n\n【服务器模组】 "..#mods_s.."个\n"
    t_util:IPairs(mods_s, show)

    str = str.."\n\n【设置修改】\n"
    t_util:IPairs(t_util:MergeList(mods_c, mods_s), function(mod)
        if t_util:GetSize(mod.settings) > 0 then
            str = str.."["..mod.name.."]\n"
            t_util:IPairs(mod.settings, function(setting)
                str = str..setting.label.." "..setting.value.."\n"
            end)
        end
    end)

    return str
end

function i_util:GetEntsInfo()
    local str = i_util:GetGameInfo()
    local Widget = require "widgets/widget"
    str = str.."\n\n\n【数量最多的前50个实体】\n"
    local ps,pr = {NULL = 0, UI = 0}, {"NULL", "UI"} 
    local e_util = require "util/entutil"
    t_util:Pairs(Ents, function(_, ent) 
        if type(ent)=="table" and ent.HasTags then
            if ent:HasTags({"widget", "ui"}) then
                ps.UI = ps.UI + 1
                return
            end
            local prefab = (type(ent.prefab)=="string" and ent.prefab) or (type(ent.name)=="string" and ent.name) or "NULL"
            if ps[prefab] then 
                ps[prefab] = ps[prefab] + 1 
            else 
                ps[prefab] = 1 
                table.insert(pr, prefab)
            end 
        end
    end)
    table.sort(pr, function(a, b) 
        return ps[a] > ps[b] 
    end) 
    for i = 1, 50 do 
        if pr[i] then
            str = str..i.."："..e_util:GetPrefabName(pr[i]).."  "..pr[i].."  "..ps[pr[i]].."\n"
        end
    end
    return str
end

function i_util:GetModsClash()
    local mods = require "data/modtable"
    local str = "【自动关闭的功能】\n"
    for i, modname in pairs(mods.close) do
        str = str..i.."："..modname.."\n"
    end
    str = str.."\n【因为以下模组功能重复或者冲突】\n"
    for i, modname in pairs(mods.clash) do
        str = str..i.."："..modname.."\n"
    end
    return str
end


local _print = print
function i_util:ClosePrint()
    print = self.NullFunction
end
function i_util:OpenPrint()
    print = _print
end
function i_util:Print(...)
    _print(...)
end
function i_util:ObsoletePrint()
    _print("群鸟绘卷", "该接口已弃用，请尽快更新！")
end


local function NullFunc()end
function i_util:GetNullFunction()
    return NullFunc
end












function i_util:ShowLData(ldata)
    local room_grounds, ground_types, room_layout = ldata.ground, ldata.ground_types, ldata.layout
    t_util:Pairs(room_grounds, function(_, room_line)
        local str = ""
        t_util:Pairs(room_line, function(_, tiledata)
            local tile = ground_types[tiledata]
            if tile then
                str = str .. tile .. ","
            else
                str = str .. "0" .. ","
            end
        end)
        
        print(str)
    end)
end

function i_util:ShowPath(path)
    local ldata = self:LoadLayout(path)
    self:ShowLData(ldata)
end



function i_util:ShowDefi(name)
    local ol = require("map/object_layout")
    local ldata = ol.LayoutForDefinition(name)
    self:ShowLData(ldata)
end


return i_util
