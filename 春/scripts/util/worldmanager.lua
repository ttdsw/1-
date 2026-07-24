local f_mana = require "util/filemanager"
local t_util = require "util/tableutil"
local m_util = require "util/modutil"

local wm_max = 50 
local wm_count = wm_max*2
local save_path = "ShroomMilkWorlds.txt"
local path_prefix, path_tail = "Saver_", ".txt"


local w_mana = f_mana(save_path)
local WM = {}



function WM:LoadData()
    return w_mana:GetSettingList("list", true)
end


function WM:SaveData()
    w_mana:Save()
end



function WM:GetSessionData(seed_player, cannew)
    local data_worlds = WM:LoadData()
    
    table.sort(data_worlds, function(a,b)
        local ta = type(a.id) == "number" and a.id or 0
        local tb = type(b.id) == "number" and b.id or 0
        return ta < tb
    end)
    local idea = t_util:IGetElement(data_worlds, function(data_world)
        return data_world.seed == seed_player and data_world.id and data_world
    end)
    if not idea and cannew then
        local count = #data_worlds
        if count < wm_count then
            
            idea = { id = count + 1, seed = seed_player}
            table.insert(data_worlds, idea)
        else
            print("群鸟绘卷：您的存档已满载，请联系开发者清理！")
            
            local data_copy = t_util:MergeList(data_worlds)
            
            table.sort(data_copy, function(a, b)
                local ta = type(a.time_entry) == "number" and a.time_entry or 0
                local tb = type(b.time_entry) == "number" and b.time_entry or 0
                return ta > tb
            end)
            local list_last = {}
            for i = 1, wm_max do
                table.insert(list_last, data_copy[i])
            end
            
            table.sort(data_copy, function(a, b)
                local ta = type(a.time_play) == "number" and a.time_play or 0
                local tb = type(b.time_play) == "number" and b.time_play or 0
                return ta > tb
            end)
            local list_long = {}
            for i = 1, wm_max do
                table.insert(list_long, data_copy[i])
            end
            
            local num
            for i = 1, wm_count do
                
                if not (t_util:IGetElement(list_last, function(data_world)
                    return data_world.id == i
                end) or t_util:IGetElement(list_long, function(data_world)
                    return data_world.id == i
                end)) then
                    num = i
                    break
                end
            end
            idea = data_worlds[num]
            if idea then
                
                local data_handle = self:OpenID(idea.id)
                data_handle:Destroy()
                idea.seed = seed_player
                print("正在为您分配新存档：", num, "种子序列号：", seed_player)
            else
                
                idea = { id = num, seed = seed_player}
                table.insert(data_worlds, idea)
                print("存档模块异常！请联系开发者！", num, seed_player)
            end
        end
    end
    m_util:print("存档序号：", idea.id, "种子：", seed_player)
    return idea
end


function WM:GetFileName(file_id)
    if file_id then
        return path_prefix..file_id..path_tail
    end
end


function WM:OpenID(file_id)
    local file_path = self:GetFileName(file_id)
    if file_path then
        return f_mana(file_path)
    end
end






function WM:GetTheSeed()
    local world = TheWorld
    local shardstate = t_util:GetRecur(world, "net.components.shardstate")
    local seed_world = t_util:GetRecur(world, "meta.session_identifier") or "defaultworldseed"
    local seed_player = shardstate and shardstate:GetMasterSessionId() or seed_world 
    return seed_player
end


function WM:GetTheID()
    local session = self:GetSessionData(self:GetTheSeed())
    return session and session.id
end


function WM:GetTheFileName()
    return self:GetFileName(self:GetTheID())
end

return WM