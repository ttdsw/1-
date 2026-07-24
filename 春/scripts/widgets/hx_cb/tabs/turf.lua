local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local f_util = require "util/fn_hxcb"
local g_util = require "util/fn_gallery"
local h_util, t_util = 
    require "util/hudutil", require "util/tableutil"
local TEMPLATES = require "widgets/redux/templates"
local m_util = require "util/modutil"



local TF = Class(Widget, function(self, CB)
    Widget._ctor(self, "huxi_console_board_turf")
    local data_str = {"width_bg", "height_bg", "size_font"}
    t_util:IPairs(data_str, function(str) self[str] = CB[str] end)
    self.CB = CB
    self.turfs = g_util.turf_all()
    self.context = {}
    self.Cates = require "data/hx_cb/cates/turf"
    self.num_col = 10
    self.num_line = math.ceil(#self.Cates.cates/10)
    self.size_cate = 40
    self.y_shift = (self.num_line-1) * (self.size_cate+4)/2
    
    self.y_cate = self.height_bg/2 - self.size_cate/1.3 - self.y_shift

    self:BuildCates()
    self:BuildDetail()
    self:SycPlayer()
    
    assert(m_util:HasModName("群鸟绘卷·夏"))
end)

function TF:BuildCates()
    local data_grid = t_util:IPairFilter(self.Cates.cates, function(data)
        local xml, tex
        if type(data.icon) == "function" then
            xml, tex = data.icon()
        else
            xml, tex = h_util:GetPrefabAsset(data.icon)
        end
        return xml and tex and {
            xml = xml,
            tex = tex,
            name = data.name,
            prefab = data.id,
            hover = data.name,
            scale = .8,
            filter = data.filter,
        }
    end)

    
    local grid_setting = {
        cell_size = 40,
        cell_spacing = 2,
        col = self.num_col,
        line = self.num_line,
        force_peek = true,
        noborderdown = true,
        noborderup = true,
        style_imgbtn = "craft",
        nosale = true,
        ensel = true,
        fn_sel = function(prefab, parent, grid, context, data)
            if prefab then
                
                context.prefab = prefab
                grid:RefreshView()
                if data.filter then
                    local pfs = t_util:IPairFilter(self.turfs, function(turf)
                        return data.filter(turf) and turf
                    end)
                    self.CB.turf_grid:SetItemsData(pfs)
                end
            end
        end,
        context = {prefab = self.Cates.default},
    }
    if h_util:IsValid(self.CB.turf_cate) then
        self.CB.turf_cate:Kill()
    end
    

    
    self.CB.turf_cate = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))
    self.CB.turf_cate:SetItemsData(data_grid)

    self.CB.turf_cate:SetPosition(-168, self.y_cate)

    local filter_default = t_util:IGetElement(self.Cates.cates, function(data)
        return data.id == self.Cates.default and data.filter
    end)
    if filter_default then
        self:BuildGrid(t_util:IPairFilter(self.turfs, function(turf)
            return filter_default(turf) and turf
        end))
    end
end

function TF:SycTurf(meta)
    local detail = self.CB.turf_detail
    local data
    if meta.prefab then
        data = t_util:IGetElement(self.turfs, function(data)
            return data.prefab == meta.prefab and data
        end)
    elseif meta.id then
        data = t_util:IGetElement(self.turfs, function(data)
            return data.id == meta.id and data
        end)
    end
    if data then
        detail.icon_show.SetPrefabIcon(data)
        detail.text_show:SetString(data.code == data.name and data.name or data.name.."\n"..data.code)
        detail.btn_finger:SetOnClick(function()
            f_util:FingerCopperStart(data.id)
        end)
        detail.btn_finger:Enable()
        if data.inv then
            detail.btn_give:Enable()
            detail.btn_give:SetHoverText("获取 20*"..data.name, {font_size = 40, offset_y = 80})
            detail.btn_give:SetOnClick(f_util:FuncExRemote(f_util:CodePrefab({[data.inv] = 20}), "生成 20 "..data.name))
        else
            detail.btn_give:Disable()
            detail.btn_give:SetHoverText("无法获取此地皮", {font_size = 40, offset_y = 80})
        end
        self.context.prefab = data.prefab
    else
        detail.icon_show.SetPrefabIcon({prefab = "cookbook_missing"})
        detail.text_show:SetString("")
        detail.btn_finger:Disable()
        detail.btn_give:Disable()
        detail.btn_give:SetHoverText("无法获取此地皮", {font_size = 40, offset_y = 80})
    end
    self.CB.turf_grid:RefreshView()
end

function TF:BuildGrid(pfs)
    
    local pos_grid_top = (self.size_cate+4) * self.num_line
    
    local grid_visable_height = self.height_bg - pos_grid_top

    
    local line_prefab = math.floor(grid_visable_height / 55)
    

    local grid_setting = {
        cell_size = 50,
        cell_spacing = 1,
        line = line_prefab,
        col = 9,
        peek_percent = 0.3,
        style_scr = "light",
        style_border = "light",
        nozoom = true,
        scroll_bar_show = true,
        context = self.context,
        fn_sel = function(prefab, ui, grid, context, data)
            if prefab then
                self:SycTurf({prefab = prefab})
            end
        end,
        fn_mid = function(prefab, parent, grid, context, data)
            if not m_util:IsMilker() or not data then return end
            local w_util = require "util/worldutil"
            local MapTile = w_util:GetWorldTiles(true)
            local pt = MapTile[data.id] and MapTile[data.id][1]
            if pt then
                f_util:ExRemote("ThePlayer.Transform:SetPosition({x},0,{z})", "{name}:({x},{z})", {x = pt.x, z = pt.z, name = data.name})
            end
        end,
    }
    if self.CB.turf_grid then
        self.CB.turf_grid:Kill()
    end
    self.CB.turf_grid = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))

    self.CB.turf_grid:SetItemsData(t_util:IPairToIPair(pfs or {}, function(data)
        return t_util:MergeMap(data, {scale = .7})
    end))
    self.CB.turf_grid:SetPosition(-164, -12-self.y_shift)

    
end

function TF:SycPlayer()
    local id
    if ThePlayer and TheWorld and TheWorld.Map then
        id = TheWorld.Map:GetTileAtPoint(ThePlayer:GetPosition():Get())
    end
    self:SycTurf({id = id})
end

function TF:BuildDetail()
    local w = Widget("grid_detail")
    
    w.icon_thank = w:AddChild(Image("images/global_redux.xml", "motd_sale_tag.tex"))
    w.icon_thank:ScaleToSize(50, 50)
    w.icon_thank:SetPosition(136, 106)
    w.icon_thank:SetTint(1, .1, .8, 1)
    h_util:BindMouseClick(w.icon_thank, {[MOUSEBUTTON_LEFT] = function()
        h_util:CreatePopupWithClose("⑨ baka ⑨", "    功能由玩家'绮'定制。\n\n留言：1 + 1 = ?", {{text = "⑨"},{text = "2"}})
    end})
    w.icon_thank:SetHoverText("󰀍特别鸣谢󰀍")

    
    w.icon_show = w:AddChild(h_util:CreatePrefabButton({
        style_imgbtn = "ui",
        size = 200
    }))
    w.icon_show:SetHoverText(STRINGS.LMB.."同步脚下地块儿", {font_size = 40, offset_y = 200})
    h_util:BindMouseClick(w.icon_show, {[MOUSEBUTTON_LEFT] = function()
        self:SycPlayer()
    end})
    w.text_show = w:AddChild(Text(NEWFONT, 30, ""))
    w.text_show:SetPosition(0, -130)

    w.btn_give = w:AddChild(TEMPLATES.StandardButton(nil, "获取地皮", {240, 80}))
    w.btn_give:SetPosition(-0, -235)
    w.btn_finger = w:AddChild(TEMPLATES.StandardButton(nil, "铺设地块儿", {240, 80}))
    w.btn_finger.image:SetTint(.4, 1, .4, 1)
    w.btn_finger:SetPosition(0, -300)


    w:SetPosition(250, 120)
    self.CB.turf_detail = self:AddChild(w)
end


return TF