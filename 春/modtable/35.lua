
local default_data = {}
local save_id, str_show = "sw_update", "开发计划"
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)

local function GetLog()
    local logtxt = require "data/theplan"
    local log = {}
    local time
    local content = ""

    for line in string.gmatch(logtxt, "[^\n]+") do
        if string.find(line, "【.-】") then
            if content ~= "" then
                table.insert(log, {
                    time = time,
                    content = content
                })
                content = ""
            end
            time = line
        elseif time then
            if string.find(line, "^%-%-") then
                
            elseif (string.len(line) == 0 or string.match(line, "^%s+$")) then
            else
                content = content .. line .. "\n"
            end
        end
    end
    if time and content ~= "" then
        table.insert(log, {
            time = time,
            content = content
        })
    end
    return log
end

local fn_left = m_util:AddBindShowScreen({
    id = save_id,
    title = str_show,
    data = GetLog(),
    type = "log"
})

local fn_right = m_util:AddBindShowScreen({
    title = str_show,
    id = "hx_" .. save_id,
    data = {}
})
m_util:AddBindIcon(str_show, "book_web_tallbird", STRINGS.LMB .. '查看在计划中要更新的', true, fn_left,
    fn_right)
