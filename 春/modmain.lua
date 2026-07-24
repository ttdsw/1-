GLOBAL.setmetatable(env, {
    __index = function(k, v)
        return GLOBAL.rawget(GLOBAL, v)
    end
})

_G.Mod_ShroomMilk = {
    PrefabCopy = {},
    Setting = {},
    Func = {
        
        WriteToMod = function(mod_id, modname)
            Mod_ShroomMilk.Mod[mod_id] = {
                name = KnownModIndex:GetModInfo(modname).name,
                path = modname
            }
        end
    },
    Mod = {
        
        
        
        
    },
    Data = {} 
}
Mod_ShroomMilk.Func.WriteToMod("春", modname)

c_util, e_util, h_util, i_util, m_util, p_util, t_util, s_mana, u_util, d_util, r_util = 
require "util/calcutil", 
require "util/entutil", 
require "util/hudutil", 
require "util/inpututil", 
require "util/modutil", 
require "util/playerutil", 
require "util/tableutil",  
require "util/settingmanager", 
require "util/userutil", 
require "util/threadutil", 
require "util/roleutil" 

local function import_mod_name(m_name)
    modimport("modtable/" .. m_name .. ".lua")
end
local function iMod(m_name)
    if type(m_name) == "table" then
        t_util:IPairs(m_name, import_mod_name)
    else
        import_mod_name(m_name or {})
    end
end
iMod("start")
local mods = require "data/modtable"
assert(not t_util:IGetElement(mods.ban, function(modname)
    return m_util:HasModName(modname)
end), Mod_ShroomMilk.Mod["春"].name .. "无法和其他合集mod同时启用")

iMod("preload")
t_util:IPairs(mods.load, function(moddata)
    local modconf, banlist, mod_name = unpack(moddata)
    if not m_util:IsTurnOn(modconf) then
        return
    end
    local modname_con = m_util:IsInBan(banlist)
    if modname_con then
        local deedname = type(banlist) == "table" and banlist[1] or banlist
        t_util:Add(mods.clash, modname_con) 
        t_util:Add(mods.close, deedname)    
    else
        iMod(mod_name)
    end
end)

if m_util:IsHuxi() then
    iMod({"modder", 35, })
end
if m_util:IsMilker() then
    iMod({"test_loop","test_temp"})
end

if os.date("%m%d") == "0401" then
    iMod({"foolsday", "cctv"})
elseif m_util:IsHuxi() then
    iMod("cctv")
end

iMod({"thanks", "end"})


i_util:AddSessionLoadFunc(function()
    if PLATFORM == "WIN32_RAIL" or IsRail() then
        local function fn_quit()
            TheSim:Quit()
        end
        h_util:CreatePopupWithClose("提示", "本mod不再支持辣鸡WeGame平台，版本号都不会写就别搬运了。", {
            {text = h_util.yes,
            cb = fn_quit}
        })
        i_util:DoTaskInTime(10, fn_quit)
    end
end)