

GLOBAL.setmetatable(env, {
    __index = function(k, v)
        return GLOBAL.rawget(GLOBAL, v)
    end
})
Mod_ShroomMilk.Func.WriteToMod("冬", modname)

c_util, e_util, h_util, i_util, m_util, p_util, t_util, s_mana, u_util, r_util, d_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/inpututil",
require "util/modutil",
require "util/playerutil",
require "util/tableutil",
require "util/settingmanager",
require "util/userutil",
require "util/roleutil",
require "util/threadutil"

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

iMod("preload")
local mod_table = {
    {
        {"sw_wortox"},
        {"恶魔人辅助", "沃托克斯辅助", "恶魔人快速治疗","Wortox Quick Heal", "no wasted souls"},
        1,
    },
    {
        "sw_wath",
        {"女武神辅助","薇格弗德辅助"},
        2,
    },
    {
        "sw_wllw",
        {"薇洛辅助", "火女辅助", "火女快捷键"},
        3,
    },
    {
        "sw_wax",
        {"麦斯威尔辅助", "老麦辅助", "老麦快捷键"},
        4,
    },
    {
        {"sw_lx"},
        {"大力士辅助", "自动健身", "健身","auto gym", "沃尔夫冈快捷键"},
        5,
    },
    {
        {"sw_woodie"},
        "伍迪辅助",
        6,
    },
    {
        "sw_wurt",
        {"沃特辅助","小鱼妹辅助","沃特快捷键","小鱼妹快捷键"},
        7,
    },
    {
        "sw_weibo",
        {"韦伯辅助","蜘蛛人辅助","韦伯快捷键", "蜘蛛人快捷键"},
        8,
    },
    {
        "sw_winona",
        {"女工辅助","薇诺娜辅助","薇诺娜快捷键", "女工快捷键", "winona tweak"},
        9,
    },
    {
        "sw_wendy",
        {"温蒂辅助","温蒂快捷键","wendy tweak"},
        10,
    },
    {
        "sw_walter",
        {"沃尔特辅助","沃尔特快捷键","walter tweak", "童子军辅助", "童子军快捷键"},
        {11,12},
    },
}

local mods = require "data/modtable"
t_util:IPairs(mod_table, function(moddata)
    local modconf, banlist, mod_name = unpack(moddata)
    if not m_util:IsTurnOn(modconf, modname) then
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
