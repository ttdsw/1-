local Image = require "widgets/image"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
local CStats = require "widgets/hx_cb/console/stats"
local CFlags = require "widgets/hx_cb/console/flags"
local CTags = require "widgets/hx_cb/console/tags"
local hxcb_squares = require "data/hx_cb/squares"
local PM = require "data/pinyin_char_map"
local Text = require "widgets/text"

local c_util, e_util, h_util, t_util = require "util/calcutil", require "util/entutil",
    require "util/hudutil", require "util/tableutil"

local f_util = require "util/fn_hxcb"
local save_data = f_util.save_data
local g_util = require "util/fn_gallery"

local CS = Class(Widget, function(self, CB)
    Widget._ctor(self, "huxi_console_board_setting")


    local data_str = {"width_bg", "height_bg", "size_font"}
    t_util:IPairs(data_str, function(str) self[str] = CB[str] end)
    self.CB = CB


    self.height_box = 40
    self.size_square = self.height_box * .8
    self.width_square = self.size_square + 5

    self.posx_1 = self.width_bg * .51 
    self.posy_1 = self.height_bg * .5 - self.height_box * .5 


    self.col_grid = 9
    self.size_cell = 50
    self.spacing_cell = 1
    self.width_cell = self.size_cell + self.spacing_cell
    self.width_grid = self.width_cell * self.col_grid
    self.grid_x = (self.posx_1 + self.size_square / 2) - self.width_cell * self.col_grid / 2
    self.width_box = self.width_grid - #hxcb_squares * self.width_square - 5

    self.size_cate = 40
    self.spacing_cate = 2 * self.spacing_cell
    self.width_cate = self.size_cate + self.spacing_cate
    self.col_cate = math.floor(self.width_grid / self.width_cate)
    self.shift_cate = .2 * self.height_box
    
    self.posy_2 = self.posy_1 - .5 * self.height_box - .5 * self.width_cate - self.shift_cate

    CB.cb_name = self:AddChild(self:BuildName())
    CB.cb_avatar = self:AddChild(self:BuildAvatar())
    
    self:SetCommandUser(UserToPlayer(f_util.load_data.userid))

    
    if save_data.lright then
        self.posx_1 = 34
        self.grid_x = -170
    end

    self:BuildEditBox(CB)
    CB.flags = self:AddChild(CFlags(self))


    
    CB.ui_tags = self:AddChild(CTags(self, CB))

    if save_data.ui_waves then
        CB.ui_waves = self:AddChild(self:BuildWaves())
    end
end)


function CS:BuildAvatar()
    local avatar = ImageButton()
    avatar:ForceImageSize(self.height_box, self.height_box)
    avatar.scale_on_focus = false
    avatar.focus_scale = {1.1, 1.1, 1.1}
    avatar.ignore_standard_scaling = true
    local x_avatar = -self.width_bg * .5
    if save_data.lright then
        x_avatar = -x_avatar
    end
    avatar:SetPosition(x_avatar, self.posy_1)
    avatar:SetHoverText(STRINGS.LMB .. "重选角色(保留科技) \n" .. STRINGS.RMB .. "重选角色(不保留科技)", {
        offset_y = 2*self.height_box
    })
    h_util:BindMouseClick(avatar, {
        [MOUSEBUTTON_LEFT] = f_util.DespawnSave,
        [MOUSEBUTTON_RIGHT] = f_util.DespawnDrop,
    })
    return avatar
end


function CS:BuildName()
    local name_id = TextBtn()
    name_id:SetFont(NEWFONT)
    name_id:SetTextSize(self.size_font + 5)
    name_id:SetTextColour(h_util:GetRGB("白色"))
    name_id:SetTextFocusColour(h_util:GetRGB("呼吸蓝"))
    name_id:SetOnClick(f_util.SetCommandUser)
    local w, h = self.width_bg/2.8, self.size_cell + 3
    name_id.image:SetSize(w, h)
    name_id.text:SetRegionSize(w, h)
    name_id.text:SetHAlign(ANCHOR_LEFT)
    name_id:SetPosition(save_data.lright and 240 or -210, self.posy_1)
    name_id.SetText = function(ui, msg) ui._base.SetText(ui, msg) end
    return name_id
end


function CS:BuildWaves()
    local function BuildWave(tex, nid, str)
        local w = Image("images/hx_icons2.xml", tex)
        local size_x, size_y = 68, 77
        local rate = 1.5
        w:ScaleToSize(size_x/rate, size_y/rate)
        w:ScaleToSize(size_x/rate, size_y/rate)
        local pos_x, pos_y = save_data.lright and 329 or -368, -281
        w:SetPosition(pos_x+nid*size_x/rate, pos_y)
        local text = w:AddChild(Text(DEFAULTFONT, 40, str))
        text:SetPosition(4, 11)
        return w
    end
    local w = Widget("waves")
    w.btn_load = w:AddChild(BuildWave("smallflag_white.tex", 0, "载"))
    w.btn_save = w:AddChild(BuildWave("smallflag_red.tex", 1, "存"))
    h_util:BindMouseClick(w.btn_load, {
        [MOUSEBUTTON_LEFT] = f_util:FuncConfirmRemote("重载游戏", "确定要重新加载游戏吗？所有未保存的进度将会丢失。", 'c_reset()', "重载游戏中..."),
        [MOUSEBUTTON_RIGHT] = function()
            if save_data.immodder then
                TheNet:SetServerPaused(false)
            end
            f_util:ConfirmRemote("保存并重载游戏", "确认要保存并重新加载游戏吗？",  "c_save() if TheWorld then TheWorld:DoTaskInTime(5, function() c_reset() end) end", "保存游戏中...5秒后将重载游戏...")
        end 
    })
    h_util:BindMouseClick(w.btn_save, {
        [MOUSEBUTTON_LEFT] = f_util:FuncExRemote("c_save()", "保存游戏..."),
    })
    return w
end





function CS:SearchGrid(str)
    local eb = h_util:IsValid(t_util:GetRecur(self, "CB.editbox"))
    if type(str)~="string" then
        str = eb and eb:GetString() or ""
    end
    local tb = h_util:IsValid(t_util:GetRecur(self, "CB.ui_tags.tag_box"))
    local func_name = tb and type(tb.name)=="string" and tb.name.."_all"
    local func_all = func_name and g_util[func_name]
    if type(func_all) ~= "function" then return end
    local func_set = t_util:GetRecur(self, "CB.grid_cells.SetPrefabs")
    if type(func_set) ~= "function" then return end
    
    if str == "" then
        if eb then
            eb:SetString("")
        end
        func_set(func_all())
    else
        func_set(t_util:IPairFilter(func_all(), function(prefab)
            if prefab:rfind_plain(str) then
                return prefab
            else
                local name = e_util:GetPrefabName(prefab)
                if name ~= e_util.NullName and PM:Find(name, str) then
                    return prefab
                end
            end
        end))
    end
    
    local cate = h_util:IsValid(t_util:GetRecur(self, "CB.grid_cates"))
    if cate then
        cate.context.prefab = str == "" and "all" or nil
        cate:RefreshView()
    end
end

function CS:BuildEditBox(CB)
    self.dir_ur = self:AddChild(Widget("ebox"))
    self.dir_ur:SetPosition(self.posx_1, self.posy_1)
    CB.editbox = self.dir_ur:AddChild(h_util:CreateTextEdit({
        width = self.width_box,
        height = self.height_box,
        font_size = self.height_box - 10,
        hover = "输入 物品的名称 或 代码 或 拼音",
        fn_enter = function(str)
            self:SearchGrid(str)
        end
    }))

    for i, square in ipairs(hxcb_squares) do
        local id = square.id .. "_square"
        local bs = self.dir_ur:AddChild(ImageButton("images/hx_square.xml", id .. ".tex"))
        self[id] = bs
        bs:ForceImageSize(self.size_square, self.size_square)
        bs:SetPosition(-(i - 1) * self.width_square, 0)
        bs.scale_on_focus = false
        bs.focus_scale = {1.1, 1.1, 1.1}
        bs.ignore_standard_scaling = true
        bs:SetHoverText(square.hover, {
            offset_y = self.height_box*1.3
        })
        bs:SetOnClick(function()
            if square.fn then
                square.fn(self)
            end
        end)
    end
    CB.editbox:SetPosition(-(#hxcb_squares - .5) * self.width_square - self.width_box / 2, 0)
end



function CS:SetCommandUser(user)
    local player = type(user) == "table" and user or ThePlayer
    local userid = player and player.userid
    local name = player and player.name or "未知"
    f_util.load_data.userid = userid or f_util.load_data.userid
    f_util.load_data.name = name
    f_util.load_data.prefab = player and player.prefab
    local avatar = h_util:IsValid(self.CB.cb_avatar)
    if avatar then
        local xml, tex = h_util:GetPrefabAsset(f_util.load_data.prefab, true)
        avatar:SetTextures(xml, tex)
    end
    local name_id = h_util:IsValid(self.CB.cb_name)
    if name_id then
        local uid = player and player.userid or ""
        name_id:SetText(subfmt("{name}({uid})", {
            name = name,
            uid = uid
        }))
        name_id:SetTextColour(h_util:GetRGB("白色"))
        name_id.image:SetHoverText(STRINGS.LMB .. "切换玩家\n".."当前对象："..name, {
            offset_y = 2*self.height_box,
            offset_x = -50,
        })
    end
    if self.stats then
        self.stats:Kill()
    end
    self.stats = self:AddChild(CStats(self))
end


return CS