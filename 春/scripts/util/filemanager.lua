local file_sys = require "util/filehandle"
local t_util = require "util/tableutil"
local MAP_ID_PREFIX,List_ID_PREFIX,Line_ID_PREFIX = file_sys:GetPrefix()




local FM = Class(function(self, filename)
    self.filename = filename
    self.data = file_sys:DataFromJsonLine(filename)
end)

function FM:GetSettingData(first)
    self.data = first and self.data or file_sys:DataFromJsonLine(self.filename)
    return self.data
end
function FM:Save()
    file_sys:FuckTableToDataFile(self.filename,self.data)
end
function FM:Destroy()
    self.data = {}
    self:Save()
end

function FM:GetSettingMap(id, first)
    self.data = self:GetSettingData(first)
    local id = MAP_ID_PREFIX..tostring(id)
    if type(self.data[id]) ~= "table" then
        self.data[id] = {}
    end
    return self.data[id]
end

function FM:GetSettingList(id, first)
    self.data = self:GetSettingData(first)
    local id = List_ID_PREFIX..tostring(id)
    if type(self.data[id]) ~= "table" then
        self.data[id] = {}
    end
    return self.data[id]
end

function FM:GetSettingLine(id, first)
    self.data = self:GetSettingData(first)
    local id = Line_ID_PREFIX..tostring(id)
    if type(self.data[id]) ~= "table" then
        self.data[id] = {}
    end
    return self.data[id]
end

function FM:SaveSettingMap(id, map)
    self.data = self:GetSettingData(true)
    self.data[MAP_ID_PREFIX..tostring(id)] = map
    self:Save()
end
function FM:SaveSettingList(id, list)
    self.data = self:GetSettingData(true)
    self.data[List_ID_PREFIX..tostring(id)] = list
    self:Save()
end
function FM:SaveSettingLine(id, line, meta)
    if type(meta) == "table" then
        t_util:Pairs(meta, function(k,v)
            line[k] = v
        end)
    end
    self.data = self:GetSettingData(true)
    self.data[Line_ID_PREFIX..tostring(id)] = line
    self:Save()
end



function FM:LoadDefault(t, key, default)
    if type(t[key]) == "nil" then
        t[key] = default
    end
    return t[key]
end

function FM:LoadDefaults(save_data, default_data)
    t_util:Pairs(default_data or {}, function(...) 
        self:LoadDefault(save_data, ...) 
    end)
end

function FM:InitLoad(save_id, default_data)
    local save_data = self:GetSettingLine(save_id, true)
    self:LoadDefaults(save_data, default_data)
    local function fn_get(id)
        return save_data[id]
    end
    local function fn_save(key)
        if key then
            return function(value)
                self:SaveSettingLine(save_id, save_data, { [key] = value })
            end
        else
            self:SaveSettingLine(save_id, save_data)
        end
    end
    return save_data, fn_get, fn_save
end



function FM:print(...)
    file_sys:LogAddFile(os.date("%I:%M:%S %p", os.time()), self.filename, ...)
end

return FM