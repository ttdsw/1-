local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local f_util = require "util/fn_hxcb"
local save_data = f_util.save_data
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local role_stats = require "data/hx_cb/stats/role"
local hxcb_stats = require "data/hx_cb/stats/basic"
local l_wet = require "widgets/hx_cb/console/lines"

local SS = Class(Widget, function(self, CS)
    Widget._ctor(self, "huxi_console_board_stats")

    self.size_stat = 38
    self.col_stat = 7
    self.spacing_stat = 2

    local data_str = {"width_bg", "height_bg"}
    t_util:IPairs(data_str, function(str) self[str] = CS[str] end)

    
    local x_stat = -self.width_bg/2
    if save_data.lright then
        x_stat = 130
    end
    self:SetPosition(x_stat, -self.height_bg/2+.55*self.size_stat)
    self:BuildStats()
end)

function SS:GetUserStats()
    local prefab = f_util.load_data.prefab or (ThePlayer and ThePlayer.prefab)
    return prefab and role_stats[prefab] or {}
end

function SS:BuildStats()
    local space = self.size_stat + self.spacing_stat
    local user_stats = self:GetUserStats()
    for i, data_stat in ipairs(t_util:MergeList(hxcb_stats, user_stats)) do
        local stat = self:AddChild(l_wet:AStat(data_stat, self.size_stat))
        local col, line = i%self.col_stat, math.ceil(i / self.col_stat)
        col = col == 0 and self.col_stat or col
        stat:SetPosition((col - 1) * space, (line-1)*space)
    end
end


return SS