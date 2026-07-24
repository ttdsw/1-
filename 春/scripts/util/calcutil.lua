local t_util = require "util/tableutil"

local c_util = {}


function c_util:GetUnitDirection(source, target)
    local dx = target.x - source.x
    local dy = target.z - source.z
    local magnitude = math.sqrt(dx*dx + dy*dy)
    if magnitude == 0 then
        return 0, 0
    end
    return dx / magnitude, dy / magnitude
end


function c_util:GetRadian(source, target)
    return math.atan2(target.z - source.z, target.x - source.x)
end


function c_util:GetAngle(source, target)
    return math.deg(self:GetRadian(source, target))
end


function c_util:GetAbsAngle(angle)
    return math.ceil(angle)%360         
end


function c_util:GetAngleDiff(a1, a2)
    local diff = self:GetAbsAngle(a1-a2)
    return diff>= 180 and 360 - diff or diff
end



local function func_line(v, min_1, max_1, min_2, max_2, func)
    if func then
        v, min_1, max_1 = func(v), func(min_1), func(max_1)
    end
    local k = (max_2 - min_2)/(max_1 - min_1)
    local b = min_2 - k * min_1
    return k * v + b
end

function c_util:GetScaleValue(scale, scale_min, scale_max, num_min, num_max)
    local v = func_line(scale, scale_min, scale_max, num_min, num_max, math.log)
    if v > num_max and v > num_min then
        return num_max > num_min and num_max or num_min
    elseif v < num_max and v < num_min then
        return num_max > num_min and num_min or num_max
    else
        return v
    end
end



function c_util:GetIntersectPotRadiusPot(center, radius, pot)
    local dx,dz = pot.x - center.x, pot.z - center.z
    local d = math.sqrt(dx * dx + dz * dz)
    
    return d == 0 and center or Vector3(center.x + radius * dx / d, 0, center.z + radius * dz / d)
end


function c_util:GetIntersectPotAnglePot(center, radius, angle)
    local rad = math.rad(angle)
    local dx, dz = math.cos(rad), math.sin(rad)
    
    return Vector3(center.x + radius * dx, 0, center.z + radius * dz)
end



function c_util:GetPerpendicularPot(center, angle, pot)
    local k1 = math.tan(math.rad(angle)) 
    local k2 = -1/k1
    local c1, c2 = center.z-k1*center.x, pot.z-k2*pot.x 
    local x3 = (c2-c1)/(k1-k2)
    local z3 = k2*x3 + c2
    return Vector3(x3, 0, z3)
end




function c_util:IsStrContains(str, item)
    return string.find(str:lower():gsub("%s+", ""), item:lower():gsub("%s+", "")) and str
end

function c_util:TrimString(s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function c_util:GetDist(x1, y1, x2, y2)
    return math.sqrt(self:GetDistWithoutSqrt(x1, y1, x2, y2))
end

function c_util:GetDistWithoutSqrt(x1, y1, x2, y2)
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end



function c_util:GreaterComn(A, B, compname, infoname, default)
    default = default or 0
    local comA = A.components[compname]
    local comB = B.components[compname]
    local numA = comA and type(comA[infoname]) == "number" and comA[infoname] or default
    local numB = comB and type(comB[infoname]) == "number" and comB[infoname] or default
    
    return numA >= numB
end

function c_util:GreaterTags(A, B, tags)
    local numA = t_util:GetElement(tags, function(_, tag)
        return table.contains(A.tags, tag)
    end) and 1 or 0
    local numB = t_util:GetElement(tags, function(_, tag)
        return table.contains(B.tags, tag)
    end) and 1 or 0
    return numA >= numB
end

function c_util:GetPosID(x, y)
    return string.format("%.2f_%.2f", x, y)
end
function c_util:GetStardPos(x, y)
    if x and y then
        return string.format("%.2f", x), string.format("%.2f", y)
    end
end

local function toBeUnique(pos_list)
    local _pos_list = {}
    t_util:IPairs(pos_list, function(pos)
        _pos_list[c_util:GetPosID(pos.x, pos.z)] = pos
    end)
    pos_list = {}
    t_util:Pairs(_pos_list, function(_, pos)
        table.insert(pos_list, pos)
    end)
    return pos_list
end

function c_util:Commu(pos_list, range, unique)
    range = range or 0
    
    pos_list = unique and toBeUnique(pos_list) or pos_list
    local count = #pos_list
    for i = 1, count do
        local pos1 = pos_list[i]
        if not pos1.id then
            pos1.id = self:GetPosID(pos1.x, pos1.y)
        end
        for j = i + 1, count do
            local pos2 = pos_list[j]
            if self:GetDist(pos1.x, pos1.y, pos2.x, pos2.y) < range then
                if not pos2.id then
                    pos2.id = pos1.id
                else
                    t_util:IPairs(pos_list, function(pos3)
                        if pos3.id == pos2.id then
                            pos3.id = pos1.id
                        end
                    end)
                end
            end
        end
    end
    local commus = {}
    t_util:IPairs(pos_list, function(pos)
        if not commus[pos.id] then
            commus[pos.id] = {pos}
        else
            table.insert(commus[pos.id], pos)
        end
    end)
    return commus
end

function c_util:isRectanglesIntersecting(A, B)  
    return not (A.x2 < B.x1 or A.x1 > B.x2 or A.z2 < B.z1 or A.z1 > B.z2)  
end

function c_util:CommusRec(pos_list, range, unique)
    range = range or 20
    pos_list = unique and toBeUnique(pos_list) or pos_list
    local commus = {}
    t_util:IPairs(pos_list, function(pos)
        local x,z = pos.x, pos.z
        local in_commu = t_util:GetElement(commus, function(commu_id, commu)
            if x > commu.x1 and x < commu.x2 and z > commu.z1 and z < commu.z2 then
                commu.x1 = x - range < commu.x1 and x - range or commu.x1 
                commu.z1 = z - range < commu.z1 and z - range or commu.z1
                commu.x2 = x + range > commu.x2 and x + range or commu.x2
                commu.z2 = z + range > commu.z2 and z + range or commu.z2 
                table.insert(commu.list, pos)
                return commu
            end
        end) 
        if in_commu then
            t_util:GetElement(commus, function(commu_id, commu)
                if commu == in_commu then return end
                if self:isRectanglesIntersecting(in_commu, commu)then
                    in_commu.x1 = in_commu.x1 < commu.x1 and in_commu.x1 or commu.x1
                    in_commu.z1 = in_commu.z1 < commu.z1 and in_commu.z1 or commu.z1
                    in_commu.x2 = in_commu.x2 > commu.x2 and in_commu.x2 or commu.x2
                    in_commu.z2 = in_commu.z2 > commu.z2 and in_commu.z2 or commu.z2
                    t_util:IPairs(commu.list, function(pos)
                        table.insert(in_commu.list, pos)
                    end)
                    commus[commu_id] = nil
                    return true
                end
            end)
        else
            table.insert(commus, {
                x1 = x - range,
                x2 = x + range,
                z1 = z - range,
                z2 = z + range,
                list = {pos}
            })
        end
    end)
    return commus
end


function c_util:CommuRec(pos_list, range, unique)
    local commus = self:CommusRec(pos_list, range, unique)
    local comm = {}
    t_util:Pairs(commus, function(_, commu)
        table.insert(comm, commu.list)
    end)
    return comm
end


function c_util:GetCenterPos(commus)
    local pos_list = {}
    t_util:Pairs(commus, function(_, commu)
        local xmin,xmax,ymin,ymax
        t_util:IPairs(commu, function(pos)
            local px, py = pos.x, pos.y
            if not xmin then
                xmin,xmax,ymin,ymax = px,px,py,py
            else
                if px<xmin then
                    xmin = px
                elseif px>xmax then
                    xmax = px
                end
                if py<ymin then
                    ymin = py
                elseif py>ymax then
                    ymax = py
                end
            end
        end)
        table.insert(pos_list, {
            x = (xmin+xmax)/2,
            y = (ymin+ymax)/2
        })
    end)
    return pos_list
end

function c_util:ModeToXY(mode, mx, my, px, py)
    mx = (mode < 3 or mode > 6) and mx or -mx
    my = (mode % 2 == 0) and my or -my
    if mode > 4 then
        mx, my = my, mx
    end
    mx, my = px + mx, py + my
    return mx, my
end
local whynum = {
    6, 8, 5, 7, 3, 1, 4, 2,
}
function c_util:ReMode(mode)
    return whynum[mode]
end


function c_util:PosToAngle(pos)
	local angle = math.atan2(pos.x, pos.z) * RADIANS + 270
	if angle < 0 then
		angle = 360 + angle
    elseif angle > 360 then
        angle = angle - 360
	end
	return angle
end

function c_util:GetFnValue(fn, v_name)
    local i = 1
    while true do
        local val_name, val_val = debug.getupvalue(fn, i)
        if val_name == v_name then
            return val_val, i
        elseif val_name == nil then
            return
        end
        i = i + 1
    end
end

function c_util:GetFnEnv(fn)
    local i = 1
    local t = {}
    if type(fn) ~= "function" then
        return t
    end
    while true do
        local name, value = debug.getupvalue(fn, i)
        if name == nil then
            return t
        end
        t[name] = value
        i = i + 1
    end
end


function c_util:FindNearMulti(number, multiple)
    return multiple==0 and number or math.floor(number / multiple + 0.5) * multiple
end


function c_util:TruncateChineseString(s, maxLength)
    local charCount = string.utf8len(s)
    if charCount <= maxLength then
        return s
    end
    local truncated = string.utf8sub(s, 1, maxLength)
    if string.utf8char(string.byte(truncated, -1)) == "" then
        truncated = string.sub(truncated, 1, -2)
    end
    return truncated .. "..."
end


function c_util:FindLargeFactors(n)
    local n_sqrt = math.floor(math.sqrt(n))
    local f1, f2 = 1, n
    for i = n_sqrt, 2, -1 do
        if n % i == 0 then
           f1, f2 = i, n/i
           break 
        end
    end
    return f1, f2
end


function c_util:FormatSecond_dms(time)
    local total = TUNING.TOTAL_DAY_TIME
    if time > total then
        local day = math.floor(time / total)
        local modtime = math.floor(time) % total
        local minute = math.floor(modtime / 60)
        local second = math.floor(modtime) % 60
        return string.format("%02d-%02d:%02d", day, minute, second)
    else
        local minute = math.floor(time / 60)
        local second = math.floor(time) % 60
        return string.format("%02d:%02d", minute, second)
    end
end
function c_util:FormatSecond_ms(time)
    local minute = math.floor(time / 60)
    local second = math.floor(time) % 60
    if minute == 0 then
        return string.format("%d秒", second)
    else
        return string.format("%d分%02d秒", minute, second)
    end
end
function c_util:FormatSecond_dos(time)
    local total = TUNING.TOTAL_DAY_TIME
    if time < total then
        return self:FormatSecond_ms(time)
    else
        return string.format("%.f天", time/total)
    end
end


function c_util:NilIsTrue(value)
   return (value == false and {false} or {true})[1]
end


function c_util:NumIn(num, a, b)
    return num >= a and num <= b
end
function c_util:NumTo(num, a, b)
    if a > num then
        return a
    elseif num < b then
        return b
    end
    return num
end

function c_util:HashEqual(a, b)
    if not (a and b) then return end
    local str_a, str_b = tostring(a), tostring(b)
    local hash_a, hash_b = hash(str_a), hash(str_b)
    local str_hash_a, str_hash_b = tostring(hash_a), tostring(hash_b)
    return t_util:IGetElement({str_a, hash_a, str_hash_a}, function(data_a)
        return t_util:IGetElement({str_b, hash_b, str_hash_b}, function(data_b)
            return data_a == data_b
        end)
    end)
end

function c_util:FormatDefault(value, default)
    local tp = type(value)
    if tp == "function" then
        return value()
    end
    if value then
        return value
    else
        if default == "table" then
            return {}
        elseif tp == "string" then
            return ""
        end
    end
end


function c_util:LoopGet(value, fn_check, fn_result, fn_next, num)
    local function fn_get(v, num)
        if not fn_check(v) or num < 0 then return end
        if fn_result(value) then return value end
        return fn_get(fn_next(v), num-1)
    end
    return fn_get(value, num or 10)
end

local function hsv_to_rgb(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local r, g, b
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return math.floor((r + m) * 255 + 0.5),
           math.floor((g + m) * 255 + 0.5),
           math.floor((b + m) * 255 + 0.5)
end


function c_util:SplitHueRing(n)
    local result = {}
    local step = 360 / n
    for i = 0, n - 1 do
        
        local hue_mid = (i * step) % 360
        local r, g, b = hsv_to_rgb(hue_mid, 1, 1)
        table.insert(result, {r/255, g/255, b/255})
    end
    return result
end


function c_util:GetCirclePoints(pot, radius, count)
    local ps = {}
    local angleStep = 2 * math.pi / count
    for i = 0, count - 1 do
        local angle = i * angleStep
        table.insert(ps, Vector3(pot.x + radius * math.cos(angle), 0, pot.z + radius * math.sin(angle)))
    end
    return ps
end

return c_util
