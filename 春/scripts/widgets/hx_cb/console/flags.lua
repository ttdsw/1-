local t_util = require "util/tableutil"
local h_util = require "util/hudutil"
local f_util = require "util/fn_hxcb"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local save_data = f_util.save_data
local flags_data = require "data/hx_cb/flags"
local ID_FLAG_DEFAULT = "common"

local FS = Class(Widget, function(self, CS)
    Widget._ctor(self, "huxi_console_board_flags")
    local data_str = {"width_bg", "height_bg", "width_grid", "width_cell", "posy_2",
                      "width_cate"}
    t_util:IPairs(data_str, function(str)
        self[str] = CS[str]
    end)

    self.size_flag = 245 / #flags_data
    self.spacing_flag = 2
    self.width_deco = self.width_bg - self.width_grid
    self.height_deco = 20

    self.pos_x = -self.width_bg * 0.5 + self.width_deco / 2 - self.width_cell * .5
    if save_data.lright then
        self.pos_x = 240
    end
    self.pos_y = self.posy_2 - self.width_cate * .5
    self.deco = self:BuildDeco()

    
    local prefab = save_data.id_flag or ID_FLAG_DEFAULT
    self.flags = self:BuildFlags(prefab)
    self:BuildFlag(prefab)
end)


function FS:BuildFlag(prefab)
    if self.flag then
        self.flag:Kill()
    end
    local ui = prefab and t_util:IGetElement(flags_data, function(data)
        return prefab == data.prefab and type(data.ui) == "function" and data.ui()
    end)
    if ui then
        self.flag = self:AddChild(ui)
        self.flag:SetPosition(self.pos_x - self.width_deco/2 + 15, self.pos_y - .5*self.height_deco)
    end
end


function FS:BuildFlags(prefab)
    local function fn_sel(prefab, parent, grid, context, data)
        
        if prefab and prefab ~= save_data.id_flag then
            context.prefab = prefab
            grid:RefreshView()
            f_util.fn_save("id_flag")(prefab)
            self:BuildFlag(prefab)
        end
    end

    local grid_setting = {
        cell_size = self.size_flag,
        cell_spacing = self.spacing_flag,
        col = #flags_data,
        line = 1,
        force_peek = true,
        noborderdown = true,
        noborderup = true,
        style_imgbtn = "craft",
        nosale = true,
        ensel = true,
        fn_sel = fn_sel,
        context = {
            prefab = prefab
        }
    }
    local data_grid = t_util:IPairFilter(flags_data, function(data)
        local xml, tex, name = h_util:GetPrefabAsset(data.icon)
        return xml and {
            xml = xml,
            tex = tex,
            name = data.name,
            prefab = data.prefab,
            hover = data.name,
            scale = .8
        }
    end)

    local line_cate = grid_setting.line
    local grid = self:AddChild(h_util:BuildGrid_PrefabButton(grid_setting))
    grid:SetItemsData(data_grid)
    grid:SetPosition(self.pos_x, self.pos_y + self.height_deco)
    return grid
end


function FS:BuildDeco()
    local deco_up = self:AddChild(Image("images/hx_ui.xml", "quagmire_recipe_line.tex"))
    deco_up:ScaleToSize(self.width_deco, self.height_deco)
    deco_up:SetPosition(self.pos_x, self.pos_y)
    return deco_up
end

return FS
