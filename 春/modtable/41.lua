local StrFading = require "widgets/huxi/str_fading"
AddClassPostConstruct("widgets/badge", function(self)
    local val_add = 0
    local num_last = 0
    local time_last = GetTime()
    if not self.num then
        return
    end
    local _SetString = self.num.SetString
    self.num.SetString = function(ui, str, ...)
        _SetString(ui, str, ...)
        local num = tonumber(str)
        if not num then
            return
        end
        local val = num - num_last
        val_add = val_add + val
        num_last = num

        self.inst:DoTaskInTime(FRAMES, function()
            local now = GetTime()
            if now - time_last > FRAMES and (val_add > 2 or val_add < -2) then
                self:AddChild(StrFading(val_add > 0 and "+" .. val_add or "" .. val_add))
            end
            val_add = 0
            time_last = now
        end)
    end
end)
