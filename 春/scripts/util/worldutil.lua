
local t_util = require "util/tableutil"
local i_util = require "util/inpututil"
local c_util = require "util/calcutil"
local h_util = require "util/hudutil"
local TILE_NONE = 0
local w_util = {}

function w_util:Enable()
    return TheWorld and TheWorld.Map and TheWorld.topology and TheWorld.topology.ids and TheWorld.topology.nodes and WORLD_TILES
end

function w_util:Init(getnew)
    self:GetWorldTiles(getnew)
    self:GetWorldNodes()
end


local MapRoom, MapId, MapNode
function w_util:GetWorldNodes()
    if not MapRoom then
        MapRoom = {}
        local tp = TheWorld.topology
        MapId = tp.ids
        MapNode = tp.nodes

        for i, task_room in ipairs(MapId) do
            local room_name = task_room:match(".*:(.*)")
            if room_name then
                local room_data = MapNode[i]
                if room_data then
                    if MapRoom[room_name] then
                        table.insert(MapRoom[room_name], {x = room_data.x, z = room_data.y})
                    else
                        MapRoom[room_name] = {{x = room_data.x, z = room_data.y}}
                    end
                end
            end
        end
    end
    return MapRoom or {}, MapId or {}, MapNode or {}
end




local MapTile, MapPos, TileList
function w_util:GetWorldTiles(getnew)
    if not MapTile or getnew then
        local map = TheWorld.Map
        local size = map:GetWorldSize()
        local pos_end = size*2
        local pos_start = -pos_end
        MapTile, MapPos, TileList = {}, {}, {}
        for x = pos_start, pos_end, 4 do
            MapPos[x] = {}
            for z = pos_start, pos_end, 4 do
                local tile = map:GetTileAtPoint(x, 0, z)
                MapPos[x][z] = tile
                if not MapTile[tile] then
                    MapTile[tile] = {}
                    table.insert(TileList, tile)
                end
                table.insert(MapTile[tile], {
                    x = x,
                    z = z
                })
            end
        end
        table.sort(TileList, function(a, b)
            return #MapTile[a] < #MapTile[b]
        end)
    end
    return MapTile or {}, MapPos or {}, TileList or {}
end

local function GetMinTile(room_tiles, lines, cols)
    local min_order, min_data, min_tile = #TileList, {i=1, j=1}, TILE_NONE
    t_util:Pairs(room_tiles, function(tile_r, data)
        if tile_r == TILE_NONE then return end
        t_util:Pairs(TileList, function(order, tile_w)
            if order <= min_order and tile_r == tile_w then
                min_order, min_data, min_tile = order, data, tile_r
            end
        end)
    end)
    local mx, mz = (min_data.i-1)*4,  (min_data.j-1)*4
    local cx, cz = lines*2, cols * 2
    return min_tile, {x = mx, z = mz}, {x = cx, z = cz}
end



function w_util:SpawnLayoutRet(room_grounds, ground_types, layer)
    if not (ground_types and room_grounds and room_grounds[1]) then
        return
    end
    layer = layer or 0
    local lines = #room_grounds + layer * 2
    local cols = #room_grounds[1] + layer * 2

    local ret, room_tiles = {}, {}
    for i = 1, lines do
        ret[i] = {}
        local x = i - layer
        for j = 1, cols do
            local z = j - layer
            local tile_code = room_grounds[x] and room_grounds[x][z]
            local tile = tile_code and ground_types[tile_code]
            if tile then
                ret[i][j] = tile
                if not room_tiles[tile] then
                    room_tiles[tile] = {
                        i = i,
                        j = j,
                    }
                end
            else
                ret[i][j] = TILE_NONE
            end
        end
    end
    local min_tile, mpos, cpos = GetMinTile(room_tiles, lines, cols)
    return ret, min_tile, mpos, cpos
end
function w_util:GetLoutCheck(mlout)
    local room_tiles = {}
    t_util:Pairs(mlout, function(i, _)
        t_util:Pairs(_, function(j, tile)
            if not room_tiles[tile] then
                room_tiles[tile] = {
                    i = i,
                    j = j,
                }
            end
        end)
    end)
    local min_tile, mpos, cpos = GetMinTile(room_tiles, #mlout, #mlout[1])
    return min_tile, mpos, cpos
end







function w_util:GetPosList(meta, mlout, mtile, mpos, cpos)
    local tiles_deny = meta.deny or {}

    local function CheckPos(pos)
        local function CheckMode(mode, init_x, init_z)
            for i = 1, #mlout do
                for j = 1, #mlout[1] do
                    local px, pz = c_util:ModeToXY(mode, (i - 1)*4, (j - 1)*4, init_x, init_z)
                    local l_tile = mlout[i][j]
                    local w_tile = MapPos[px] and MapPos[px][pz]
                    
                    if not w_tile or (l_tile == TILE_NONE and table.contains(tiles_deny, w_tile)) or (l_tile ~= TILE_NONE and l_tile ~= w_tile) then
                        return true
                    end
                end
            end
        end

        for mode = 1, 8 do
            local init_x, init_z = c_util:ModeToXY(mode, -mpos.x, -mpos.z, pos.x, pos.z)
            if not CheckMode(mode, init_x, init_z) then
                local x, z = c_util:ModeToXY(mode, cpos.x-2, cpos.z-2, init_x, init_z)
                return {
                    x = x,
                    z = z,
                    mode = c_util:ReMode(mode),
                }
            end
        end
    end

    if meta.only then
        local r_data = meta.room and MapRoom[meta.room]
        local n_pos = r_data and r_data[1]
        if n_pos then
            local room_range = meta.room_range or 64
            return {
                t_util:IGetElement(MapTile[mtile], function(t_pos)
                    if c_util:GetDist(n_pos.x, n_pos.z, t_pos.x, t_pos.z) < room_range then
                        return CheckPos(t_pos)
                    end
                end)
            }
        else
            return {t_util:IGetElement(MapTile[mtile], CheckPos)}
        end
    else
        return t_util:IPairFilter(MapTile[mtile], CheckPos)
    end
end



function w_util:GetTileResult(tilename, meta)
    MapTile, MapPos, TileList = self:GetWorldTiles(meta.getnew)
    local pos_list = {}
    local tiles = WORLD_TILES[tilename] and MapTile[WORLD_TILES[tilename]]
    if tiles then
        pos_list = t_util:PairToIPair(c_util:CommusRec(tiles, meta.range), function(_, commu)
            return {
                x = (commu.x1 + commu.x2)/2,
                z = (commu.z1 + commu.z2)/2
            }
        end)
    end
    return pos_list
end

function w_util:GetLoutResult(mlout, meta)
    local mtile, mpos, cpos = self:GetLoutCheck(mlout)
    return {
        pos_list = self:GetPosList(meta, mlout, mtile, mpos, cpos),
    }
end

function w_util:GetPathResult(path, meta)
    local ldata = i_util:LoadLayout(path)
    if not ldata then return end
    local room_grounds, ground_types, room_layout = ldata.ground, ldata.ground_types, ldata.layout
    local mlout, mtile, mpos, cpos = self:SpawnLayoutRet(room_grounds, ground_types, meta.layer)
    
    return mlout and mtile~=TILE_NONE and {
        pos_list = self:GetPosList(meta, mlout, mtile, mpos, cpos),
        layout = room_layout,
    }
end

function w_util:GetDefiResult(name, meta)
    local ol = require("map/object_layout")
    local ldata = ol.LayoutForDefinition(name)
    if not ldata then return end
    local room_grounds, ground_types, room_layout = ldata.ground, ldata.ground_types, ldata.layout
    local mlout, mtile, mpos, cpos = self:SpawnLayoutRet(room_grounds, ground_types, meta.layer)
    if not mlout or mtile == TILE_NONE then return end
    local pos_list = self:GetPosList(meta, mlout, mtile, mpos, cpos)
    if meta.alone then
        local alone_list = t_util:IPairToPair(pos_list, function(pos)
            return c_util:GetPosID(pos.x, pos.z), pos
        end)
        pos_list = t_util:PairToIPair(alone_list, function(_, pos)
            return pos
        end)
    end
    return {
        pos_list = pos_list,
        layout = room_layout,
    }
end


function w_util:Test()
end

function w_util:ShowLayout(mlout)
    t_util:Pairs(mlout, function(_, room_line)
        local str = ""
        t_util:Pairs(room_line, function(_, tile)
            if tile then
                str = str .. tile .. ","
            else
                str = str .. "0" .. ","
            end
        end)
        str = str .. "\n"
        print(str)
    end)
end

local i_debug = 0
function w_util:GoNext()
    self:GoTo(i_debug + 1)
end
function w_util:GoLast()
    self:GoTo(i_debug - 1)
end

function w_util:GoTo(i)
    local tp = TheWorld.topology
    local ids = tp.ids
    if i > #ids then
        i = #ids
        print("已经是最后一个节点了！")
    elseif i < 1 then
        i = 1
        print("已经是第一个节点了！")
    end
    i_debug = i
    local node = tp.nodes[i]
    
    i_util:GoTo(node.x, node.y)
    print(i, ids[i_debug], node.type, node.c, node.area, table.concat(node.tags, " | "))
end

local i_layouts
function w_util:GetLayout()
    if not i_layouts then
        local objs = require("map/layouts")
        local traps = require("map/traps")
        local pois = require("map/pointsofinterest")
        local protres = require("map/protected_resources")
        local boons = require("map/boons")
        local maze_rooms = require("map/maze_layouts")
        require "debugcommands"
        i_layouts = {}
        t_util:Pairs(objs.Layouts, function(name)
            table.insert(i_layouts, {name = name, path = "objs"})
        end)
        t_util:Pairs(traps.Layouts, function(name)
            table.insert(i_layouts, {name = name, path = "traps"})
        end)
        t_util:Pairs(pois.Layouts, function(name)
            table.insert(i_layouts, {name = name, path = "pois"})
        end)
        t_util:Pairs(protres.Layouts, function(name)
            table.insert(i_layouts, {name = name, path = "protres"})
        end)
        t_util:Pairs(boons.Layouts, function(name)
            table.insert(i_layouts, {name = name, path = "boons"})
        end)
        table.sort(i_layouts, function(a, b)
            if a.path == b.path then
                return a.name < b.name
            else
                return a.path < b.path
            end
        end)
    end
    return i_layouts
end
local l_debug = 0
function w_util:LNext()
    self:LGoTo(l_debug + 1)
end
function w_util:LLast()
    self:LGoTo(l_debug - 1)
end
function w_util:LGoTo(i)
    local ids = self:GetLayout()
    if i > #ids then
        i = #ids
        print("已经是最后一个布局了！")
    elseif i < 1 then
        i = 1
        print("已经是第一个布局了！")
    end
    l_debug = i
    self:d_spawnlayout(ids[i].name)
    print(i, ids[i].path, ids[i].name)
end
local function _SpawnLayout_AddFn(prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
    local x = (points_x[current_pos_idx] - width/2.0)  * TILE_SCALE
    local y = (points_y[current_pos_idx] - height/2.0) * TILE_SCALE

    x = math.floor(x*100) / 100.0
    y = math.floor(y*100) / 100.0

    if not prefab_data then return end
    prefab_data.x = x
    prefab_data.z = y

    prefab_data.prefab = prefab

    local ent = SpawnSaveRecord(prefab_data)
    if not ent then return end
    ent:LoadPostPass(Ents, FunctionOrValue(prefab_data.data))

    if ent.components.scenariorunner ~= nil then
        ent.components.scenariorunner:Run()
    end
end


function w_util:d_spawnlayout(name)
    local obj_layout = require("map/object_layout")
    local layout  = obj_layout.LayoutForDefinition(name)
    local map_width, map_height = TheWorld.Map:GetSize()

    local add_fn = {
        fn = _SpawnLayout_AddFn,
        args = {entitiesOut={}, width=map_width, height=map_height, rand_offset=false}
    }

    local offset = layout.ground ~= nil and (#layout.ground / 2) or 0
    local size = layout.ground ~= nil and (#layout.ground * TILE_SCALE) or nil

    local pos  = ConsoleWorldPosition()
    local x, z = TheWorld.Map:GetTileCoordsAtPoint(pos:Get())

    if size ~= nil then
        for i, ent in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, size, nil, { "player", "INLIMBO", "FX" })) do 
            ent:Remove()
        end
    end

    obj_layout.Place({x-offset, z-offset}, name, add_fn, nil, TheWorld.Map)
end


return w_util
