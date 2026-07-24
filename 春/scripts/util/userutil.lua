local m_util = require "util/modutil"
local h_util = require "util/hudutil"
local t_util = require "util/tableutil"

local u_util = {}


local where_default
local function getwheredefault()
    where_default = m_util:IsTurnOn("pos_say")
    return where_default
end

local _last_say_time = 0
function u_util:Say(who, what, where, color, ignoremeanwhile)
    if (GetTime() - _last_say_time < 3) and not ignoremeanwhile then
        return
    end
    _last_say_time = GetTime()
    where = where or where_default or getwheredefault()
    local rgb = h_util:GetRGB(color)
    what = type(what) == "boolean" and (what and "开启" or "关闭") or what
    if where == "head" then
        local content = ""
        if who and what then
            content = who.."："..what
        else
            content = type(who) ~= "nil" and content..who or content
            content = type(what) ~= "nil" and content..what or content
        end
        if ThePlayer and ThePlayer.components.talker then
            ThePlayer.components.talker:Say(content, nil, nil, nil, nil, rgb)
        end
    elseif where == "self" then
        what = what and tostring(what) or ""
        ChatHistory:AddToHistory(ChatTypes.Message, nil, nil, who, what, rgb)
    elseif where == "net" then
        TheNet:Say(who)
    end
end


function u_util:GetSkinsData()
    local skins = {
        dupes = {},
        shops = {},
        zeros = {}
    }
    self.prefabs_dupe = {}
    
    t_util:Pairs(GetOwnedItemCounts(), function(item_key, item_count)
        local spools = TheItems:GetBarterSellPrice(item_key) 
        local inshop = IsItemMarketable(item_key) 
        local meta = { prefab = item_key, count = item_count, spool = spools, cate = nil }
        local tname
        
        if item_count > 1 and spools > 0 and not inshop then
            tname = "dupes"
        elseif inshop then
            
            tname = "shops"
        elseif spools == 0 then
            
            tname = "zeros"
        end
        if tname then
            meta.cate = tname
            table.insert(skins[tname], meta)
        end
    end)
    
    t_util:Pairs(skins, function(tname, info)
        table.sort(info, function(a,b)
            if a.spool == b.spool then
                if a.count == b.count then
                    local ra, rb = GetModifiedRarityStringForItem(a.prefab), GetModifiedRarityStringForItem(b.prefab)
                    if ra:len() == rb:len() then
                        if ra == rb then
                            return a.prefab < b.prefab
                        else
                            return ra > rb
                        end
                    else
                        return ra:len() > rb:len()
                    end
                else
                    return a.count > b.count
                end
            else
                return a.spool > b.spool
            end
        end)
    end)

    return skins
end


return u_util