local m_util, t_util, w_mana, h_util, c_util, e_util = require "util/modutil", require "util/tableutil",
    require "util/worldmanager", require "util/hudutil", require "util/calcutil", require "util/entutil"









local Watcher = Class(function(self, inst)
    self.inst = inst
    
    self:ResetData()
    self.anim_ceil = 500
    self.anims_ignore = {}
    
    
    local pusher = m_util:GetPusher()
    if pusher then
        pusher:RegNearStart(inst, function(x, z)
            self:StartUpdate()
        end, function()
            self:StopUpdate()
        end)
    end
    self.func = {}
end)

function Watcher:ResetData()
    self.anim = nil
    self.anims = {}
    self.data = {}
    self.data_last = {}
end

function Watcher:SetAnimCeil(num)
    self.anim_ceil = num
end

function Watcher:StartUpdate()
    self.inst:StartUpdatingComponent(self)
end

function Watcher:StopUpdate()
    self.inst:StopUpdatingComponent(self)
    self:ResetData()
end

function Watcher:OnUpdate(dt)
    
    
    local bank, anim, frame = self.inst.AnimState:GetHistoryData()
    if anim then
        local now = GetTime()
        if anim ~= self.anim and not self.anims_ignore[anim] then
            self.anim = anim
            
            self.anims[anim] = now
            table.insert(self.data, {
                time = now,
                anim = anim
            })
            if #self.data > self.anim_ceil then
                self.data_last = self.data
                self.data = {}
            end
        end
        if self.func[anim] then
            self.func[anim](now-self:GetLastData(-1).time)
        end
    end
end



function Watcher:GetAnimTime(anim, min)
    local t
    if type(anim) == "table" then
        if min then
            t = GetTime()
            t_util:IPairs(anim, function(an)
                t = math.min(self.anims[an] or t, t)
            end)
        else
            t = 0
            t_util:IPairs(anim, function(an)
                t = math.max(self.anims[an] or 0, t)
            end)
        end
    else
        t = self.anims[anim] or 0
    end
    return t
end

function Watcher:IgnoreAnim(anim)
    if type(anim) == "table" then
        t_util:IPairs(anim, function(an)
            self.anims_ignore[an] = true
        end)
    else
        self.anims_ignore[anim] = true
    end
end
function Watcher:GetNowAnim()
    return self.anim
end

function Watcher:GetLastData(num)
    local id = num + 1 + #self.data
    return self.data[id] or self.data_last[#self.data_last + id]
end

function Watcher:GetLastAnim(num)
    local data = self:GetLastData(num)
    return data and data.anim
end
function Watcher:ListenAnim(anim, func)
    self.func[anim] = func
end

return Watcher
