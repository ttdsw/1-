local Widget = require "widgets/widget"
local Text = require "widgets/text"
local shift = 10 
local ft = 1 
local scale = 1.5 

local StrFading = Class(Widget, function(self, str)
    Widget._ctor(self, "StrFading")

    self.text = self:AddChild(Text(BODYTEXTFONT, 33, str))
    self:StartUpdating()
end)

function StrFading:OnUpdate()
    local vt = GetTime() - self.inst.spawntime
    if vt > 0 then
        self:SetPosition(0, shift / ft * vt, 0)
        self.text:SetColour(1, 1, 1, -1 / ft * vt + 1)
        self.text:SetScale((scale - 1) / ft * vt + 1)
        if vt > ft then
            self:Kill()
        end
    end
end

return StrFading
