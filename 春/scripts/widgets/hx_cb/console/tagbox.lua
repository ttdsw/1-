local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local h_util = require "util/hudutil"
local m_util = require "util/modutil"
local f_util = require "util/fn_hxcb"
local g_util = require "util/fn_gallery"
local t_util = require "util/tableutil"
local e_util = require "util/entutil"
local save_data = f_util.save_data

local Cates = Class(Widget, function(self, TS, name, info, CB)
    Widget._ctor(self, name or "tag")

    local data_str = {"size_cate", "spacing_cate", "col_cate", "grid_x", "posy_2", "width_cate", 
    "height_bg", "width_cell", "shift_cate", "size_cell", "spacing_cell", "col_grid", "width_grid", "height_bg",}
    t_util:IPairs(data_str, function(str) self[str] = TS[str] end)
    
    self.posy_unit = self.size_cate/2 - self.height_bg/2 + self.shift_cate/2

    self.CB = CB



    
    local prefab_unit = f_util:LoadUnit(name)

    info = info or {}
    if info.cates then
        self:BuildCates(info.cates, info.default)
        self:BuildUnits(prefab_unit)
    elseif type(info.poi)=="function" then
        self:BuildPoi(info.poi(), info)
    end
end)


function Cates:BuildCates(cates, cate_default)
    self.data_cates = cates or {}
    
    local id_cate = f_util:LoadCate(self.name, cate_default)


    local data_grid = t_util:IPairFilter(self.data_cates, function(data)
        local xml, tex
        if type(data.icon) == "function" then
            xml, tex = data.icon()
        end
        if (not xml or not tex) and type(data.icon)=="string" then
            xml, tex = h_util:GetPrefabAsset(data.icon)
        end
        return xml and tex and {
            xml = xml,
            tex = tex,
            name = data.name,
            prefab = data.id,
            hover = data.name,
            scale = .8
        }
    end)
    
    
    self.line_cates = math.ceil(#data_grid / self.col_cate)

    local grid_setting = {
        cell_size = self.size_cate,
        cell_spacing = self.spacing_cate,
        col = self.col_cate,
        line = self.line_cates,
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
                
                f_util:SaveCate(self.name, prefab)
                
                self:BuildCate(prefab)
                
                if m_util:IsMilker() then
                    self.CB.editbox:SetString(prefab)
                end
            end
        end,
        context = {
            prefab = id_cate
        },
        zero_show = "",
        fn_rr = function(prefab)
            local fn = t_util:IGetElement(self.data_cates or {}, function(data_cate)
                return data_cate.id == prefab and data_cate.fn_rr
            end)
            if type(fn) == "function" then
                fn()
            end
        end
    }
    if h_util:IsValid(self.CB.grid_cates) then
        self.CB.grid_cates:Kill()
    end
    

    
    self.CB.grid_cates = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))
    self.CB.grid_cates:SetItemsData(data_grid)
    
    self.CB.grid_cates:SetPosition(self.grid_x, self.posy_2 - (self.line_cates - 1) * self.width_cate * .5)

    
    self:BuildCate(id_cate)
end

function Cates:BuildCate(id_cate)
    if h_util:IsValid(self.CB.grid_cells) then
        self.CB.grid_cells:Kill()
    end
    local data_sel = t_util:IGetElement(self.data_cates or {}, function(data_cate)
        return data_cate.id == id_cate and data_cate
    end)
    if not data_sel then
        return
    end
    local prefabs_get = data_sel.prefabs
    if prefabs_get then
        self:BuildPrefabs(type(prefabs_get)=="function" and prefabs_get() or prefabs_get, data_sel)
    end
    
end


local function func_prefab_left(isunit)
    return function (prefab, self, grid, context, data)
    if prefab then
            if context.prefab == prefab or not save_data.spawn_ensure or isunit then
                f_util:ExRemote(f_util:CodePrefab({prefab}), "生成 "..data.name)
            end
            if not isunit then
                context.prefab = prefab
                grid:RefreshView()
                self:BuildUnits(prefab)
                f_util:SaveUnit(self.name, prefab)
            end
            
            if m_util:IsMilker() then
                self.CB.editbox:SetString(prefab)
            end
        end
    end
end
local function func_prefab_right(isunit)
    return function (prefab, self, grid, context, data, x, y)
        if prefab then
            if not isunit then
                context.prefab = prefab
                grid:RefreshView()
                self:BuildUnits(prefab)
                f_util:SaveUnit(self.name, prefab)
            end
            local meta = {x = x, y = y, isunit = isunit}
            f_util:MakePrefabMenu(self.CB, prefab, f_util:GetPrefabMenu(prefab, meta), meta)
            
            
            if m_util:IsMilker() then
                self.CB.editbox:SetString(prefab)
            end
        end
    end
end
local function fn_prefab_mid(prefab)
    if prefab then
        local mid_str = save_data.midbind or "R_SpawnMany"
        local ret = f_util[mid_str] and f_util[mid_str](f_util, f_util:GetPrefabShow(prefab))
        if ret then
            ret.cb()
        end
    end
end

function Cates:BuildPrefabs(prefabs, meta)
    local line_cates = self.line_cates or 0
    
    local pos_grid_top = self.posy_2 - (line_cates - .5) * self.width_cate
    
    
    local pos_grid_bottom = self.posy_unit + .5*self.width_cate + .4*self.width_cate
    
    local grid_visable_height = pos_grid_top - pos_grid_bottom

    
    local line_prefab = math.floor(grid_visable_height / self.width_cell)
    

    
    local grid_y = pos_grid_bottom + grid_visable_height/2


    
    
    local grid_setting = {
        cell_size = self.size_cell,
        cell_spacing = self.spacing_cell,
        line = line_prefab,
        col = self.col_grid,
        peek_percent = 0.3,
        style_scr = "light",
        style_border = "light",
        nozoom = true,
        scroll_bar_show = true,
        context = {prefab = f_util:LoadUnit(self.name)},
        fn_sel = func_prefab_left(false),
        fn_rr = func_prefab_right(false),
        fn_mid = fn_prefab_mid,
        zero_color = UICOLOURS.GOLD_FOCUS,
    }

    grid_setting.scrollbar_offset = -self.width_grid - .5 * grid_setting.cell_size

    
    grid_setting.scrollbar_height_offset = self.height_bg -
                                               (self.width_cell * (grid_setting.line + grid_setting.peek_percent)) - 40

    self.CB.grid_cells = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))

    self.CB.grid_cells.SetPrefabs = function(pfs)
        self.CB.grid_cells:SetItemsData(t_util:IPairFilter(pfs or {}, function(prefab)
            return f_util:GetPrefabShow(prefab, {scale = .7})
        end))
    end
    if meta.hot and not meta.nosort then
        table.sort(prefabs, g_util.SortSB)
    end
    self.CB.grid_cells.SetPrefabs(prefabs)


    
    self.CB.grid_cells:SetPosition(self.grid_x, grid_y)
    local posx_bar, posy_bar = -self.width_grid / 2 - grid_setting.cell_size / 2, -grid_y
    if save_data.lright then
        posx_bar = - posx_bar
    end
    self.CB.grid_cells.scroll_bar_container:SetPosition(posx_bar, posy_bar)
end

function Cates:BuildUnits(id_unit)
    local list_prefab = g_util:UnitsGet(id_unit) or {}
    if h_util:IsValid(self.CB.grid_units) then
        self.CB.grid_units:Kill()
    end
    local data_prefab = {}
    for _, prefab in ipairs(list_prefab)do
        local name = e_util:GetPrefabName(prefab)
        local name_got = name ~= e_util.NullName
        table.insert(data_prefab, f_util:GetPrefabShow(prefab, {scale = .8}))
        
        if #data_prefab >= self.col_cate then
            break
        end
    end
    local grid_setting = {
        cell_size = self.size_cate,
        cell_spacing = self.spacing_cate,
        col = self.col_cate,
        line = 1,
        force_peek = true,
        noborderdown = true,
        noborderup = true,
        style_imgbtn = "inv",
        nosale = true,
        zero_show = "",
        fn_sel = func_prefab_left(true),
        fn_rr = func_prefab_right(true),
        fn_mid = fn_prefab_mid,
    }
    self.CB.grid_units = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))
    self.CB.grid_units:SetItemsData(data_prefab)
    self.CB.grid_units:SetPosition(self.grid_x, self.posy_unit)
end

function Cates:BuildPoi(prefabs, meta)
    
    local pos_grid_top = self.posy_2 +.5 * self.width_cate
    
    
    local pos_grid_bottom = self.posy_unit
    
    local grid_visable_height = pos_grid_top - pos_grid_bottom

    
    local line_prefab = math.floor(grid_visable_height / self.width_cell)
    

    
    local grid_y = pos_grid_bottom + grid_visable_height/2


    
    
    local grid_setting = {
        cell_size = self.size_cell,
        cell_spacing = self.spacing_cell,
        line = line_prefab,
        col = self.col_grid,
        peek_percent = 0.3,
        style_scr = "light",
        style_border = "light",
        nozoom = true,
        noborderdown = true,
        noborderup = true,
        scroll_bar_show = true,
        fn_sel = function(prefab, self, grid, context, data)
            if prefab then
                local ret = f_util:R_FindNext(f_util:GetPrefabShow(prefab))
                if ret then
                    ret.cb()
                end
            end
        end,
        fn_rr = function (prefab, self, grid, context, data, x, y)
            if prefab then
                f_util:MakePrefabMenu(self.CB, prefab, f_util:GetPoiMenu(prefab), {x = x, y = y})
            end
        end,
        zero_color = UICOLOURS.GOLD_FOCUS,
    }

    grid_setting.scrollbar_offset = -self.width_grid - .5 * grid_setting.cell_size

    
    grid_setting.scrollbar_height_offset = self.height_bg -
                                               (self.width_cell * (grid_setting.line + grid_setting.peek_percent)) - 40

    self.CB.grid_cells = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))
    

    self.CB.grid_cells.SetPrefabs = function(pfs)
        self.CB.grid_cells:SetItemsData(t_util:IPairFilter(pfs or {}, function(prefab)
            local pdata = f_util:GetPrefabShow(prefab, {scale = .7})
            
            pdata.hover = pdata.name
            return pdata
        end))
    end
    self.CB.grid_cells.SetPrefabs(prefabs)


    
    self.CB.grid_cells:SetPosition(self.grid_x, grid_y)
    local posx_bar, posy_bar = -self.width_grid / 2 - grid_setting.cell_size / 2, -grid_y
    if save_data.lright then
        posx_bar = - posx_bar
    end
    self.CB.grid_cells.scroll_bar_container:SetPosition(posx_bar, posy_bar)
end

return Cates
