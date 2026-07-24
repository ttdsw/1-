


local SB = require("screens/redux/scrapbookdata")
local t_util = require("util/tableutil")
local e_util = require "util/entutil"

local subcats={}
t_util:Pairs(SB, function(_, data)
    t_util:Add(subcats, data.subcat)
end)
local rets = {}
subcats = t_util:IPairFilter(subcats, function(subcat)
    t_util:Pairs(SB, function(prefab, line)
        if line.subcat == subcat then
            if rets[subcat] then
                rets[subcat] = rets[subcat] + 1
            else
                rets[subcat] = 1
            end
        end
    end)
end)
subcats = t_util:PairToIPair(rets, function(subcat, count)
    return count >= 4 and subcat
end)


table.sort(subcats)

t_util:SubIPairs({


}, subcats)

local i = 0
print("***********************************")
local cates = t_util:IPairFilter(subcats, function(subcat)
    i = i+1
    if i < 100 then
        print('"'..subcat..'",')
        return {
            id = subcat,
            icon = "filter_none",
            name = subcat,
            prefabs = function()
                return t_util:PairToIPair(SB, function(prefab, line)
                    return line.subcat == subcat and prefab
                end)
            end,
        }
    end
end)



return {
    cates = cates,
}