AddClassPostConstruct("widgets/uiclock", function(self)
    function self:UpdateCaveClock()
        self:OpenCaveClock()
    end

    local _OpenCaveClock = self.OpenCaveClock
    function self:OpenCaveClock(...)
        self.UpdateCaveClock = function()
        end
        self.CloseCaveClock = function()
        end
        return _OpenCaveClock(self, ...)
    end
end)
