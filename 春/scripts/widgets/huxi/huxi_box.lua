local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local Text = require "widgets/text"
local c_util, e_util, h_util, m_util, t_util,p_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil",
require "util/playerutil"

local hud_xml = "images/hud.xml"
local half_w, half_h = h_util.screen_w/2, h_util.screen_h/2

local SBox = Class(Widget, function(self)
    Widget._ctor(self, "SBox")
    self.img_size = 50
    self.img_a_size = 1.1*self.img_size
    self.y_space = 1.1*self.img_a_size
end)

function SBox:SetData(data, pos, isscreenpos)
    if self.data~=data then
        self.data = data
        if self.root then self.root:Kill() end
        if data and tonumber(data.num) then
            self.num = tonumber(data.num)
            self.root = self:AddChild(Widget("root"))
            self.col, self.line = c_util:FindLargeFactors(self.num)
            if self.num > 12 then
                self.line, self.col = self.col, self.line
            end
            local ui = self.root:AddChild(self:BuildUI())
        end
    end
    if pos and self.col then
        local w, h = self.col * self.img_a_size, self.line * self.img_a_size
        local mx, my
        if isscreenpos then
            mx = pos.x - (self.col-1)*0.5*self.img_a_size
            my = pos.y < 1.5*half_h and pos.y + self.y_space + h or pos.y-self.img_a_size
        else
            local x, y = TheSim:GetScreenPos(pos.x, 0, pos.z)
            mx = x - 0.5*w + 0.5*self.img_a_size
            my = y < half_h and h + y + self.y_space or y - self.y_space
        end
        self:SetPosition(mx, my)
        self:SetClickable(false)
    end
end

function SBox:BuildUI()
    local w = Widget("ui")
    local col = self.col
    for i = 1, self.num do
        local slot = Image(hud_xml, "inv_slot.tex")
        slot:ScaleToSize(self.img_size, self.img_size)
        local data = self.data[i] or self.data[tostring(i)]
        if data then
            local xml, tex = h_util:ZipXml(data.xml, true), data.tex
            if xml and tex then
                if not TheSim:AtlasContains(xml, tex) then
                    xml, tex = h_util:GetPrefabAsset(data.prefab)
                end
                if xml and tex and TheSim:AtlasContains(xml, tex) then
                    local img = slot:AddChild(Image(xml, tex))
                    local stack = tonumber(data.stack)
                    if stack and stack > 1 then
                        stack = stack > 999 and "999+" or stack
                        local text = img:AddChild(Text(NUMBERFONT, 45))
                        text:SetString(stack)
                        text:SetPosition(0, 0.25*self.img_size)
                    end
                end
            end
        end
        local num_x, num_y = (i-1)%col, math.floor((i-1)/col)
        slot:SetPosition(num_x*self.img_a_size, -num_y*self.img_a_size)
        w:AddChild(slot)
    end
    return w
end


return SBox