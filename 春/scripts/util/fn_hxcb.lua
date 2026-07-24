local c_util, e_util, h_util, m_util, t_util, p_util = require "util/calcutil", require "util/entutil",
    require "util/hudutil", require "util/modutil", require "util/tableutil", require "util/playerutil"
local u_util = require "util/userutil"
local s_mana = require "util/settingmanager"
local RePrefabs = require("data/redirectdata").prefab_func
local TelePrefabs = require("data/redirectdata").prefab_tele
local RMenu = require "widgets/hx_cb/console/rmenu"
local i_util = require "util/inpututil"
local TAGS = require "data/hx_cb/tags"

local default_data = {
    tip_pos = m_util:IsHuxi() and "self" or "whisper",
    code_pri = false,
    pop_ensure = true,
    range_delete = 3, 
    range_kill = m_util:IsHuxi() and 64 or 20, 
    lright = false,
    code_hover = m_util:IsHuxi(),
    spawn_ensure = not m_util:IsHuxi(),
    __authorize = m_util:IsMilker(),
    skin_enable = true,
    tags = {
        
    },
    units = {
        
    },
    num_spawn = 10, 
    midbind = "R_SpawnMany",
    equipmem = true,
    modfilter = true,
    favs = {food = {"shroomcake", "vegstinger"}},
    spawn_anchor = true,
    poi_forest = {'multiplayer_portal', "MOD_HUXI_cave_entrance", "pigking", 
    "moonbase", "oasislake", "critterlab", "chester_eyebone", "stagehand", 
    "moon_fissure", "beequeen", "klaus_sack", "moose_nesting_ground", "dragonfly", "antlion",
    "terrarium", "crabking", "hermitcrab", "walrus_camp", "statueglommer", "MOD_HUXI_sculpture_carry",
    "MOD_HUXI_sculpture_fixed", "MOD_HUXI_moon_altar", "wormhole", "lightninggoat", "beefalo", "deer",
    "watertree_pillar", "saltstack", "waterplant", "malbatross", "monkeyqueen", "lunarrift_portal",
    "daywalker2", "sharkboi", "balatro_machine","wagpunk_workstation"},
    poi_cave = {"cave_exit", "tentacle_pillar", "atrium_gate", "archive_lockbox_dispencer",
    "archive_switch", "archive_orchestrina_base", "ancient_altar", "hutch_fishbowl", "minotaur",
    "toadstool_cap", "rabbithouse", "monkeybarrel", "slurtlehole", "spiderhole", "rocky", "mushgnome",
    "daywalker", "shadowrift_portal","cave_vent_mite", "mushtree_tall", "mushtree_medium", "mushtree_small"},
    scale_main = 1,
    scale_menu = 1,
    immodder = false,
    ui_waves = m_util:IsHuxi(),
}
local save_data, fn_get, fn_save = s_mana:InitLoad("sw_T_mine", default_data)












local f_util = {
    
    load_data = {},
    save_data = save_data,
    fn_get = fn_get,
    fn_save = fn_save,
}
local function fnSmark(str)
    return "'"..str.."'"
end
local function Subfmt(s, tag)
    local tab = {}
    t_util:Pairs(tag, function(k, v)
        tab[k] = tostring(v)
    end)
    return (s:gsub('(%b{})', function(w) return tab[w:sub(2, -2)] or w end))
end


function f_util:GetSavePoi()
    if TheWorld and TheWorld:HasTag("cave") then
        return save_data.poi_cave or {}
    else
        return save_data.poi_forest or {}
    end
end


function f_util:GetUserInfo()
    local CB = ThePlayer and ThePlayer.userid and h_util:GetCB()
    return self.load_data.userid and {name = string.gsub(c_util:TruncateChineseString(self.load_data.name, 8), "'", ""), uid = fnSmark(self.load_data.userid), pid = fnSmark(ThePlayer.userid), prefab = self.load_data.prefab}
end

function f_util:IsMine()
    return ThePlayer and ThePlayer.userid and ThePlayer.userid == self.load_data.userid
end


function f_util:SetCommandUser()
    m_util:AddBindShowScreen({
        id = "CB_NAME_ID",
        title = "选择指令操作对象",
        data = function()
            local CB = h_util:GetCB()
            return CB and t_util:IPairFilter(TheNet:GetClientTable() or {}, function(pdata)
                local pname = c_util:TruncateChineseString(pdata.name or "", 10)
                return pdata.prefab and pdata.prefab ~= "" and pdata.userid and {
                    id = pdata.userid,
                    label = pname,
                    hover = pdata.userid,
                    type = "imgstr",
                    prefab = pdata.prefab,
                    fn = function()
                        local function BindUser()
                            if h_util:IsValid(CB.tab_box) then
                                CB.tab_box:SetCommandUser(pdata)
                            end
                            m_util:PopShowScreen()
                        end
                        
                        if pdata.userid == f_util.load_data.userid or (pdata.userid == (ThePlayer and ThePlayer.userid)) then
                            BindUser()
                        else
                            h_util:CreatePopupWithClose("绑定玩家",
                                "你确定将指令对象设置为【" .. pname ..
                                    "】吗？\n注意：如果该玩家和你不在同一世界，指令将执行失败。",
                                {{
                                    text = h_util.no
                                }, {
                                    text = "绑定",
                                    cb = BindUser
                                }})
                        end
                    end
                }
            end)
        end
    })()
end


function f_util:ExRemote(str_code, str_tip, meta)
    
    if type(str_code) ~= "string" then return m_util:print("非法指令", str_code) end
    local info = self:GetUserInfo()
    if not info then return end
    info = t_util:MergeMap(info, meta or {})
    if save_data.code_pri then print("【远控面板】执行指令：\n"..Subfmt(str_code, info)) end
    str_code = " "..str_code

    if type(str_tip) == "string" and str_tip ~= "" then
        str_tip = Subfmt(str_tip, info)
        local CB = h_util:GetCB()
        local cb_name = CB.cb_name
        if h_util:IsValid(cb_name) then
            cb_name:SetText(str_tip)
            cb_name:SetTextColour(h_util:GetRGB("黄色"))
        end
        if save_data.tip_pos == "whisper" then
            info.tip = fnSmark(str_tip, info)
            str_code = "_U_.components.talker:Say({tip})"..str_code
        elseif save_data.tip_pos == "mine" then
            info.tip = fnSmark(str_tip, info)
            str_code = "_P_.components.talker:Say({tip})"..str_code
        elseif save_data.tip_pos == "only" then
            u_util:Say(str_tip, nil, "head", "呼吸蓝", true)
        elseif save_data.tip_pos == "ann" then
            info.tip = fnSmark("【远控面板】"..str_tip)
            str_code = "TheNet:Announce({tip})"..str_code
        elseif save_data.tip_pos == "self" then
            u_util:Say("【远控面板】", str_tip, "self", nil, true)
        end
    end

    local str_start = "local _U_,_P_=UserToPlayer({uid}),UserToPlayer({pid})if not _U_ then return _P_.components.talker:Say({lost})end "
    info.lost = fnSmark("该玩家和你不在同一世界，无法执行指令！")

    local code_str = Subfmt(str_start..str_code, info)
    
    
    i_util:ExRemote(code_str)
end


function f_util:ConfirmRemote(title, content, str_code, str_tip, meta, fn_end)
    local info = self:GetUserInfo()
    if not info then return end
    local func_yes = function()
        self:ExRemote(str_code, str_tip, meta)
        if fn_end then
            fn_end()
        end
    end
    if save_data.pop_ensure then
        info = t_util:MergeMap(info, meta or {})
        h_util:CreatePopupWithClose(Subfmt(title, info), Subfmt(content, info), {{text = h_util.yes, cb = func_yes}, {text = h_util.no}})
    else
        func_yes()
    end
end


function f_util:DespawnSave()
    if TheWorld and TheWorld:HasTag("forest") then
        f_util:ConfirmRemote("重选角色", "确定要让 {name} 重选角色吗？\n（物品掉落，并保留科技！）", [[
        local giver = UserToPlayer({uid})
        if not giver and TheWorld then return end
        giver:PushEvent("ms_playerreroll")
        if giver.components.inventory then
            giver.components.inventory:DropEverything()
        end
        if giver.components.leader  then
            local ff = giver.components.leader.followers
            for k, v in pairs(ff) do
                if k.components.inventory then
                    k.components.inventory:DropEverything()
                elseif k.components.container then
                    k.components.container:DropEverything()
                end
            end
        end
        TUNING._MdSp1 = TUNING._MdSp1 or {}
        TUNING._MdSp2 = TUNING._MdSp2 or {}
        TUNING._MdSp1[giver.userid] = giver.SaveForReroll and giver:SaveForReroll()
        TUNING._MdSp2[giver.userid] = giver:GetPosition()
        TheWorld:ListenForEvent("ms_newplayerspawned",function(w, p)
            local id = p.userid
            if not id then return end
            if p.LoadForReroll and TUNING._MdSp1[id] then
                p:LoadForReroll(TUNING._MdSp1[id])
            end
            TUNING._MdSp1 = TUNING._MdSp1 or {}
            TUNING._MdSp1[id] = nil
            p:DoTaskInTime(.5, function()
                local pos = TUNING._MdSp2[id]
                if pos and p.Transform then
                    p.Transform:SetPosition(pos:Get())
                end
                TUNING._MdSp2 = TUNING._MdSp2 or {}
                TUNING._MdSp2[id] = nil
            end)
        end)
        TheWorld:PushEvent("ms_playerdespawnanddelete", giver)
    ]], "玩家 {name} 保留科技重选角色")
    else
        h_util:CreatePopupWithClose("提示", "该功能只能在地表使用, 请试试右键换角色吧。")
    end
end


function f_util:DespawnDrop()
    f_util:ConfirmRemote("重选角色", "确定要让 {name} 重选角色吗？\n（物品不会掉落，而且会清空科技！）", "c_despawn({uid})", "玩家 {name} 无科技重选角色")
end


function f_util:CodePrefab(prefabs)
    local str = "local inv=_U_.components.inventory if not inv then return end local pt=_U_:GetPosition()"
    local ret, names = {}, {}
    t_util:Pairs(prefabs or {}, function(k, v)
        local prefab, num
        if type(k) == "number" and type(v) == "string" then
            prefab, num = v, 1
        elseif type(v) == "number" and type(k) == "string" then
            prefab, num = k, v
        end
        if prefab then
            local prefab, code_done = self:RePrefab(prefab)
            local skin = Profile:GetLastUsedSkinForItem(prefab)
            skin = save_data.skin_enable and skin
            str = str..subfmt(
                "for i=1,{num} do local IT=SpawnPrefab({prefab},{skin},nil,{uid})if IT then if IT.components.inventoryitem and not _U_:HasTag('playerghost')then inv:GiveItem(IT)else IT.Transform:SetPosition(pt.x,pt.y,pt.z)end {code_done}end end ", 
            {prefab = fnSmark(prefab), num = num, skin=skin and fnSmark(skin) or "nil", uid = "_P_.userid", code_done = code_done or ""})
            if not ret[prefab] then
                ret[prefab] = true
                table.insert(names, e_util:GetPrefabName(prefab))
            end
        end
    end)
    return str, table.concat(names, ",")
end

function f_util:CodePrefabAt(prefab, x, z)
    local prefab, code_done = self:RePrefab(prefab)
    local skin = Profile:GetLastUsedSkinForItem(prefab)
    skin = save_data.skin_enable and skin
    local str = "local IT=SpawnPrefab({prefab},{skin},nil,{uid})if IT then IT.Transform:SetPosition({px},0,{pz})end {code_done}"
    str = subfmt(str, {prefab = fnSmark(prefab), skin=skin and fnSmark(skin) or "nil", uid = "_P_.userid", code_done = code_done or "", px = x, pz = z})
    return str
end


function f_util:RePrefab(prefab)
    local ret = RePrefabs[prefab]
    if ret then
        return ret.prefab or prefab, type(ret.done) == "string" and ret.done.." "
    else
        return prefab
    end
end


function f_util:GetPrefabShow(prefab, meta)
    local name = e_util:GetPrefabName(prefab)
    local name_got = name ~= e_util.NullName
    local prefab_re = self:RePrefab(prefab)
    return t_util:MergeMap({
        prefab = prefab, 
        name = name_got and name or prefab,
        hover = name_got and (save_data.code_hover and name .. "\n" .. prefab_re or name) or prefab_re,
    }, meta or {})
end


function f_util:CodeFull()
    return 'local function Full(v)if v:HasTag("playerghost")then v:PushEvent("respawnfromghost")v.rezsource="【远控面板】"end local C=v.components local a,b,c,d,e=C.health,C.sanity,C.hunger,C.moisture,C.temperature if a and b and c and d and e then a:SetPenalty(a.penalty-1)a:SetPercent(1)b:SetPercent(1)c:SetPercent(1)d:SetPercent(0)e:SetTemperature(25)a:ForceUpdateHUD(true)end end '
end



function f_util:FindNext(prefabs)
    prefabs = TelePrefabs[prefabs] or prefabs
    prefabs = type(prefabs) == "table" and prefabs or {prefabs}
    return subfmt('local pfs={_PFS}local pents={}local nents=table.invert(pfs)for _,e in pairs(Ents)do if table.contains(pfs,type(e) == "table" and e.IsValid and e:IsValid()and e.HasTag and not e:HasTag("inlimbo")and e.prefab)then table.insert(pents,e)end end table.sort(pents,function(a,b)if nents[a.prefab]==nents[b.prefab]then return a.GUID<b.GUID else return nents[a.prefab]<nents[b.prefab] end end)local tent if TUNING._tele_GUID then local loc=0 for i,e in ipairs(pents)do if e.GUID==TUNING._tele_GUID then loc=i break end end tent=pents[loc+1]or pents[1]else tent=pents[1]end if tent then TUNING._tele_GUID=tent and tent.GUID if tent.Transform then _U_.Transform:SetPosition(tent.Transform:GetWorldPosition())end end', {_PFS = "{"..json.encode(prefabs):sub(2,-2).."}"})
end


function f_util:fnSmark(str)
    return fnSmark(str)
end


function f_util:CodeEnts(str)
    local code_FF = ' local pt=_U_:GetPosition()for _,o in ipairs(TheSim:FindEntities(pt.x,pt.y,pt.z,64,{"_health"},{"player"}))do if FF then FF(o)end end'
    return ('local function FF(o)')..str.." end"..code_FF
end
function f_util:CodeGhost()
    return 'if _U_:HasTag("playerghost") then return end '
end


function f_util:FuncExRemote(str_code, str_tip, meta)
    return function()
        return f_util:ExRemote(str_code, str_tip, meta)
    end
end
function f_util:FuncConfirmRemote(title, content, str_code, str_tip, meta, fn_end)
    return function()
        return self:ConfirmRemote(title, content, str_code, str_tip, meta, fn_end)
    end
end




function f_util:SaveCate(name, value)
    if type(name) == "string" then
        save_data.tags["cate_"..name] = tostring(value)
        f_util.fn_save()
    end
end
function f_util:LoadCate(name, default)
    return t_util:GetRecur(save_data, "tags.cate_"..tostring(name)) or default or "all"
end
function f_util:SaveUnit(name, value)
    if type(name) == "string" then
        save_data.units["prefab_"..name] = tostring(value)
        f_util.fn_save()
    end
end
function f_util:LoadUnit(name, default)
    return t_util:GetRecur(save_data, "units.prefab_"..tostring(name)) or default
end





function f_util:R_SpawnMany(data)
    return {
        text = "批量生成", 
        cb = self:FuncExRemote(
                self:CodePrefab({[data.prefab] = save_data.num_spawn}), 
                "生成"..save_data.num_spawn.."*"..data.name
            )
    }
end


local prefab_findnext
function f_util:R_FindNext(data)
    local got = data.prefab == prefab_findnext
    return {
        text = got and "传送至下一个" or "传送",
        cb = function()
            prefab_findnext = data.prefab
            self:ExRemote(
                self:FindNext(data.prefab),
                (got and "下一个" or "传送至").." "..data.name
            )
        end 
    }
end


function f_util:R_GetRecipe(data)
    local ings = t_util:GetRecur(AllRecipes, data.prefab..".ingredients")
    local names = {}
    local ret = t_util:PairToIPair(ings or {}, function(_, info)
        if type(info) == "table" then
            local ing, amount = info.type, info.amount
            if type(ing) == "string" and type(amount) == "number" and Prefabs[ing] then
                table.insert(names, e_util:GetPrefabName(ing).."*"..amount)
                return {ing, amount}
            end
        end
    end)
    if ret[1] then
        local prefabs = t_util:IPairToPair(ret, function(data)
            return data[1], data[2]
        end)
        local name_str = "("..table.concat(names, ",")..")"
        return {
            text = "获取材料"..name_str,
            cb = self:FuncExRemote(self:CodePrefab(prefabs), "获取"..data.name.."的材料")
        }
    end
end


function f_util:R_AddFavorite(data, meta)
    if meta and meta.isunit then
        return
    end
    
    local tag_sel = save_data.id_tag
    local text, func
    local isfav
    local name_tag = ""
    local cate_sel = self:LoadCate(tag_sel)
    if tag_sel == "poi" then
        return
    end
    if tag_sel == "fav" and not (cate_sel == "all" and data.prefab == t_util:GetPrefab() and m_util:IsMilker()) then
        isfav = true
        if cate_sel == "all" then
            
            if data.prefab == t_util:GetPrefab() then
                return {
                    text = "这是什么",
                    cb = function()
                        h_util:CreatePopupWithClose("提示", "【收藏】分类的第一项始终是你最后宣告的物品，\n并不是真的记录为收藏了。")
                    end
                }
            else
                
                func = function()
                    t_util:Pairs(save_data.favs, function(_, ps)
                        t_util:Sub(ps or {}, data.prefab)
                    end)
                    local ui = h_util:GetCB()
                    if ui then  ui:BuildUI() end
                end
            end
        else
            
            local tag_name = self:GetTagName(cate_sel)
            name_tag = tag_name and "("..tag_name..")" or name_tag
            func = function()
                t_util:Sub(save_data.favs[cate_sel] or {}, data.prefab)
                local ui = h_util:GetCB()
                if ui then  ui:BuildUI() end
            end
        end
    elseif tag_sel ~= "all" and tag_sel ~= "fav" then
        
        local tag_name = self:GetTagName(tag_sel)
        name_tag = tag_name and "("..tag_name..")" or name_tag
        local favs_tag = save_data.favs[tag_sel] or {}
        if table.contains(favs_tag, data.prefab) then
            
            isfav = true
            func = function()
                t_util:Sub(favs_tag, data.prefab)
            end
        else
            
            func = function()
                if save_data.favs[tag_sel] then
                    t_util:Add(save_data.favs[tag_sel], data.prefab)
                else
                    save_data.favs[tag_sel] = {data.prefab}
                end
            end
        end
    else
        
        local tag = t_util:GetElement(save_data.favs, function(tag, ps)
            return table.contains(ps, data.prefab) and tag
        end)
        if tag then
            
            isfav = true
            local tag_name = self:GetTagName(tag)
            name_tag = tag_name and "("..tag_name..")" or name_tag
            func = function()
                t_util:Pairs(save_data.favs, function(_, ps)
                    t_util:Sub(ps or {}, data.prefab)
                end)
            end
        else
            
            func = function()
                tag = t_util:IGetElement({"craft", "creature", "food", "equip", "items", "ground", "mod"}, function(id)
                    local g_util = require "util/fn_gallery"
                    local prefabs = g_util[id.."_all"]()
                    return table.contains(prefabs, data.prefab) and id
                end) or "all"
                if save_data.favs[tag] then
                    t_util:Add(save_data.favs[tag], data.prefab)
                else
                    save_data.favs[tag] = {data.prefab}
                end
            end
        end
    end
    return {
        text = (isfav and "取消收藏" or "添加至收藏")..name_tag,
        cb = function()
            func()
            f_util.fn_save()
        end
    }
end


function f_util:R_AddRecipe(data)
    if not self:IsMine() then return end
    local var = t_util:GetRecur(ThePlayer, "replica.builder.classified.recipes."..data.prefab)
    if var then
        if not var:value() and not ThePlayer.replica.builder:KnowsRecipe(data.prefab) then
            return {
                text = "解锁原型",
                cb = self:FuncExRemote('_P_.components.builder:AddRecipe("{prefab}")', "解锁{name}原型", data)
            }
            
            
            
            
            
        end
    end
end
function f_util:R_AddBluePrint(data)
    local pbp = data.prefab.."_blueprint"
    if Prefabs[pbp] then
        return {
            text = "获取蓝图",
            cb = self:FuncExRemote(f_util:CodePrefab({pbp}), "获取{name}蓝图", data)
        }
    end
end

local function GetGridPoint(x)
    local v = (x - 2) / 4
    local n = v >= 0 and math.floor(v + 0.5) or math.ceil(v - 0.5)
    return 2 + 4 * n
end

function f_util:FingerEnd()
    t_util:IPairs({"goldhandler", "silverhandler", "copperhandler", "hgrid", "hgrid_expand", "hgrid_x"}, function(mountstr)
        if self[mountstr] then
            self[mountstr]:Remove()
            self[mountstr] = nil
        end
    end)
    if ThePlayer then
        ThePlayer.HUD:Show()
        ThePlayer.HUD.under_root:Show()
        if h_util:IsValid(ThePlayer.HUD.twolines) then
            ThePlayer.HUD.twolines:Kill()
        end
    end
end

function f_util:UpdateTurfPos(x, z)
    if e_util:IsValid(self.hgrid) then 
        self.hgrid.Transform:SetPosition(TheWorld.Map:GetTileCenterPoint(x, 0, z))
    else 
        self.hgrid = SpawnPrefab("hgrid") 
    end
end

function f_util:UpdateGridPos(x, z)
    self:UpdateTurfPos(x, z)
    if save_data.spawn_anchor then
        local xt, zt = math.floor(x * 2 + 0.5)/2, math.floor(z * 2 + 0.5)/2
        
        
        if e_util:IsValid(self.hgrid_expand) then
            self.hgrid_expand.Transform:SetPosition(xt, 0, zt)
        else
            self.hgrid_expand = SpawnPrefab("hgrid_expand")
        end
        if e_util:IsValid(self.hgrid_x) then
            self.hgrid_x.Transform:SetPosition(xt, 0, zt)
        else
            self.hgrid_x = SpawnPrefab("hgrid_x")
        end
        return xt, zt
    else
        if e_util:IsValid(self.hgrid_x) then
            self.hgrid_x.Transform:SetPosition(x, 0, z)
        else
            self.hgrid_x = SpawnPrefab("hgrid_x")
        end
        return x, z
    end
end

function f_util:FingerGoldStart(prefab)
    if not m_util:InGame() or self.goldhandler then return end
    h_util:FocusTwoline(STRINGS.LMB.."点击生成  "..STRINGS.RMB.."退出金手指")
    self.GoldFinger = prefab
    
    
    self.goldhandler = TheInput:AddMoveHandler(function(x, y)
        if self.GoldFinger then
            local x, _, z = TheSim:ProjectScreenPos(x, y)
            if x then
                self:UpdateGridPos(x, z)
            end
        elseif self.goldhandler then
            self:FingerEnd()
        end
    end)
end
function f_util:FingerSilverStart()
    if not m_util:InGame() or self.silverhandler then return end
    h_util:FocusTwoline(STRINGS.LMB.."拖拽实体  "..STRINGS.RMB.."退出银手指")
    self.SiverFinger = true
    self.silverhandler = TheInput:AddMoveHandler(function(msx, msy)
        if self.SiverFinger then
            if e_util:IsValid(self.SiverTarget) and type(self.SiverFinger)=="table" then
                
                local x, _, z = TheSim:ProjectScreenPos(msx-self.SiverFinger.x, msy-self.SiverFinger.y)
                if x then
                    local ewx, ewz = self:UpdateGridPos(x, z)
                    self.SiverTarget.Transform:SetPosition(ewx, 0, ewz)
                    self.SiverTarget._ewx, self.SiverTarget._ewz = ewx, ewz
                end
            else
                
                t_util:IPairs({"hgrid", "hgrid_expand", "hgrid_x"}, function(mountstr)
                    if self[mountstr] then
                        self[mountstr]:Remove()
                        self[mountstr] = nil
                    end
                end)
            end
        elseif self.silverhandler then
            self:FingerEnd()
            
        end
    end)
end
function f_util:FingerCopperStart(tile_id)
    if not m_util:InGame() or self.copperhandler then return end
    h_util:FocusTwoline(STRINGS.LMB.."按住铺设  "..STRINGS.RMB.."退出铺设")
    self.CopperFinger = tile_id
    self.copperhandler = TheInput:AddMoveHandler(function(x, y)
        if self.CopperFinger then
            local x, _, z = TheSim:ProjectScreenPos(x, y)
            if x then
                self:UpdateTurfPos(x, z)
                if TheInput:IsControlPressed(CONTROL_PRIMARY) then
                    local X, Y = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
                    if not X then return end
                    if TheWorld.Map:GetTile(X, Y) ~= self.CopperFinger then
                        self:ExRemote("if TheWorld.Map:GetTile({X},{Y})~={tile_id} then TheWorld.Map:SetTile({X},{Y},{tile_id})end", nil, {tile_id = self.CopperFinger, X = X, Y = Y})
                    end
                end
            end
        elseif self.copperhandler then
            self:FingerEnd()
        end
    end)
end

function f_util:FingerStop()
    if self.GoldFinger or self.CopperFinger or self.SiverFinger then
        
        self.GoldFinger = nil
        self.CopperFinger = nil
        
        self.SiverFinger = nil
        return true
    end
end

function f_util:FingerGold()
    if not self.GoldFinger then return end
    local pos = TheInput:GetWorldPosition()
    local x, z = pos.x, pos.z
    if save_data.spawn_anchor then
        x, z = math.floor(x * 2 + 0.5)/2, math.floor(z * 2 + 0.5)/2
    end
    self:ExRemote(self:CodePrefabAt(self.GoldFinger, x, z))
    h_util:PlaySound("collect_item")
    return true
end

function f_util:FingerCopper()
    if not self.CopperFinger then return end
    local X, Y = TheWorld.Map:GetTileCoordsAtPoint(TheInput:GetWorldPosition():Get())
    if not X then return end
    if TheWorld.Map:GetTile(X, Y) ~= self.CopperFinger then
        self:ExRemote("if TheWorld.Map:GetTile({X},{Y})~={tile_id} then TheWorld.Map:SetTile({X},{Y},{tile_id})end", nil, {tile_id = self.CopperFinger, X = X, Y = Y})
    end
    return true
end


function f_util:FingerSilver()
    local entmouse = self.SiverTarget
    if entmouse and entmouse.Transform and entmouse.Network and type(self.SiverFinger)=="table" then
        if entmouse._transtask then
            entmouse._transtask:Cancel()
            entmouse._transtask = nil
        end
        if TheWorld and TheWorld.ismastersim then return end
        local msx, msy = TheSim:GetPosition()
        local x, _, z = TheSim:ProjectScreenPos(msx-self.SiverFinger.x, msy-self.SiverFinger.y)
        if save_data.spawn_anchor then
            x, z = math.floor(x * 2 + 0.5)/2, math.floor(z * 2 + 0.5)/2
        end
        i_util:ExRemote(subfmt('for _,e in pairs(Ents)do if e and e.Network and e.Network:GetNetworkID()=={NetID} and e.Transform then e.Transform:SetPosition({x},0,{z})break end end', {NetID = entmouse.Network:GetNetworkID(), x=x, z=z}))
    end
end



function f_util:FingerSilverDown(entmouse)
    if not self.SiverFinger then return end
    
    self:FingerSilver()
    if entmouse and entmouse.Transform and entmouse.Network then
        local ep = entmouse:GetPosition()
        local esx, esy = TheSim:GetScreenPos(ep.x, 0, ep.z)
        local msx, msy = TheSim:GetPosition()
        self.SiverFinger = {x=msx-esx, y=msy-esy}
        self.SiverTarget = entmouse
        
        if entmouse._transtask then
            entmouse._transtask:Cancel()
            entmouse._transtask = nil
        end
        entmouse._transtask = entmouse:DoPeriodicTask(FRAMES, function(inst)
            if inst._ewx then
                inst.Transform:SetPosition(inst._ewx, 0, inst._ewz)
            end
        end)
    end
    return true
end
function f_util:FingerSilverUp()
    if not self.SiverFinger then return end
    self:FingerSilver()
    self.SiverTarget = nil
    return true
end


function f_util:R_SpawnRunning(data)
    return {
        text = "金手指模式",
        cb = function()
            self:FingerGoldStart(data.prefab)
        end 
    }
end


function f_util:R_CountPrefab(data)
    return {
        text = "宣告实体数量",
        cb = self:FuncExRemote('local c1,c2=0,0 for k,v in pairs(Ents)do if v.prefab == "{prefab}" then c1=c1+1 c2=c2+(v and v.components and v.components.stackable and v.components.stackable:StackSize()or 1)end end c_announce(c1==0 and "找不到{name}。" or "当前世界有"..c1.."堆、共"..c2.."个{name}。")', "宣告{name}数量",data)
    }
end


function f_util:R_ClearRange(data)
    return {
        text = "清理附近"..data.name,
        cb = self:FuncExRemote('local pt=_U_:GetPosition()local ents=TheSim:FindEntities(pt.x,pt.y,pt.z,64,nil,{"inlimbo","player"})for k,v in pairs(ents)do if v.prefab=="{prefab}" then v:Remove() end end', "清理附近"..data.name, data),
    }
end

function f_util:R_RemoveAll(data)
    return {
        text = "移除所有"..data.name,
        cb = self:FuncConfirmRemote("警告", "确定要移除所有{name}吗？\n这将删除全世界的{name}！\n包括箱子里的，物品栏和背包的所有{name}！", 'c_removeall("{prefab}")', "移除所有{name}", data)
    }
end

function f_util:R_AddTelePoi(data)
   local iscave = TheWorld and TheWorld:HasTag("cave")
   local save_poi = self:GetSavePoi()
   local inpoi = table.contains(save_poi, data.prefab)
   local strcave = iscave and "(洞穴)" or "(森林)"
   local strpoi = inpoi and "取消传送点" or "记录为传送点"
   return {
        text = strpoi..strcave,
        cb = function()
            if inpoi then
                t_util:Sub(save_poi, data.prefab)
            else
                t_util:Add(save_poi, data.prefab)
            end
            fn_save()
            local ui = h_util:GetCB()
            if ui then ui:BuildUI() end
        end
   }
end
function f_util:R_UpTelePoi(data)
   local save_poi = self:GetSavePoi()
   local iop_evas = table.invert(save_poi)
   local pos = iop_evas[data.prefab]
   if pos and pos > 1 then
    return {
        text = "列表中前移",
        cb = function()
            t_util:Sub(save_poi, data.prefab)
            table.insert(save_poi, pos-1, data.prefab)
            fn_save()
            local ui = h_util:GetCB()
            if ui then  ui:BuildUI() end
        end
    }
   end
end
function f_util:R_DownTelePoi(data)
   local save_poi = self:GetSavePoi()
   local iop_evas = table.invert(save_poi)
   local pos = iop_evas[data.prefab]
   if pos and pos < #save_poi then
    return {
        text = "列表中后移",
        cb = function()
            t_util:Sub(save_poi, data.prefab)
            table.insert(save_poi, pos+1, data.prefab)
            fn_save()
            local ui = h_util:GetCB()
            if ui then ui:BuildUI() end
        end
    }
   end
end


function f_util:GetPrefabMenu(prefab, meta)
    local items,meta = {}, meta or {}
    local data = self:GetPrefabShow(prefab)
    t_util:True(items, self:R_SpawnMany(data))
    t_util:True(items, self:R_SpawnRunning(data))
    t_util:True(items, self:R_FindNext(data))
    t_util:True(items, self:R_GetRecipe(data))
    t_util:True(items, self:R_AddFavorite(data, meta))
    t_util:True(items, self:R_AddRecipe(data))
    t_util:True(items, self:R_AddBluePrint(data))
    t_util:True(items, self:R_CountPrefab(data))
    t_util:True(items, self:R_ClearRange(data))
    t_util:True(items, self:R_AddTelePoi(data))
    t_util:True(items, self:R_RemoveAll(data))

    
    
    
    
    return items
end


function f_util:R_ResetTelePoi()
    return {
        text = "重置传送列表",
        cb = function()
            h_util:CreatePopupWithClose("注意", "真的要恢复默认的传送列表吗？此操作不可撤销！", {
                {
                    text = h_util.no,
                },
                {
                    text = "就要重置",
                    cb = function()
                        local save_poi = self:GetSavePoi()
                        local incave = TheWorld and TheWorld:HasTag("cave")
                        local defaut_poi = incave and default_data.poi_cave or default_data.poi_forest
                        t_util:Clear(save_poi)
                        t_util:IPairs(defaut_poi, function(prefab)
                            table.insert(save_poi, prefab)
                        end)
                        local ui = h_util:GetCB()
                        if ui then ui:BuildUI() end
                        h_util:PlaySound("learn_map")
                    end
                },
            })
        end
    }
end


function f_util:GetPoiMenu(prefab)
    local items = {}
    local data = self:GetPrefabShow(prefab)
    t_util:True(items, self:R_AddTelePoi(data))
    t_util:True(items, self:R_ResetTelePoi(data))
    t_util:True(items, self:R_UpTelePoi(data))
    t_util:True(items, self:R_DownTelePoi(data))
    return items
end

function f_util:MakePrefabMenu(UI, prefab, menudata, meta)
    if h_util:IsValid(UI.right_menu) then
        UI.right_menu:Kill()
    end
    UI.right_menu = UI:AddChild(RMenu(menudata))
    UI.right_menu:SetGPos(meta.x, meta.y)
    
        
    
end



function f_util:GetTagIcon(tag)
    return t_util:IGetElement(TAGS, function(data)
        return data.id == tag and data.icon
    end) 
end
function f_util:GetTagName(tag)
    return t_util:IGetElement(TAGS, function(data)
        return data.id == tag and data.name
    end) 
end


function f_util.Fn_SuperGodMode()
    local l = f_util.load_data
    l.supergod = not l.supergod
    local tip_str = l.supergod and '超级上帝模式：开启' or '超级上帝模式：关闭'
    l.godmode = false
    local code_str = l.supergod 
    and '_U_.task_supergod = _U_:DoPeriodicTask(1,function(_U_)local h = _U_.components.health if h then h:SetInvincible(true) end end)local h = _U_.components.health if h then h:SetInvincible(true)end'
    or 'local h=_U_.components.health if not h then return end h:SetInvincible(false)'
    f_util:ExRemote('if _U_:HasTag("playerghost") then _U_:PushEvent("respawnfromghost") _U_.rezsource = "【远控面板】" end if _U_.task_supergod then _U_.task_supergod:Cancel() _U_.task_supergod = nil end '..code_str, tip_str)
end

function f_util.Fn_CraftMode()
    local l = f_util.load_data
    l.freebuildmode = not l.freebuildmode
    local tip_str = l.freebuildmode and '创造模式：开启' or '创造模式：关闭'
    local code_str = "local h = _U_.components.builder if h then h.freebuildmode=not {freebuildmode} h:GiveAllRecipes() end"
    f_util:ExRemote(f_util:CodeGhost()..code_str, tip_str, {freebuildmode = l.freebuildmode})
end

function f_util.Fn_HealthyLock()
    local l = f_util.load_data
    l.minhealth = not l.minhealth
    local tip_str = (l.minhealth and '锁定最小生命值：1' or '不锁定生命值')
    local code_str = 'local h=_U_.components.health if not h then return end '..(l.minhealth and 'h:SetMinHealth(1)' or 'h:SetMinHealth(0)')
    f_util:ExRemote(f_util:CodeGhost()..code_str, tip_str)
end

return f_util