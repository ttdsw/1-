local t_util = require "util/tableutil"
local c_util = require "util/calcutil"
local i_util = require "util/inpututil"
local PrefabNames = require("data/redirectdata").prefab_name
local EntUtil = {
    NullName = "未知",
}


function EntUtil:IsValid(ent, dead_not_valid)
    return type(ent) == "table" and ent.entity and ent:IsValid() and ent.Transform
end



function EntUtil:InValidPos(ent)
    if self:IsValid(ent) then
        if TheWorld:HasTag("cave") then
            return ent:IsOnValidGround()
        else
            
            return ent:IsOnValidGround() or not ent:IsOnOcean(false)
        end
    end
end


function EntUtil:GetContainer(ent)
    if ent and ent.replica then
        return ent.replica.container or ent.replica.inventory
    end
end


function EntUtil:GetContUI(ent)
    local coners = t_util:GetRecur(ThePlayer, "HUD.controls.containers")
    return t_util:GetElement(coners, function(cont, ui)
        return cont == ent and ui
    end)
end


function EntUtil:GetPrefabSlot(prefab, cont)
    local container = prefab and self:GetContainer(cont)
    return container and t_util:GetElement(container:GetItems(), function(slot, item)
        return item and item.prefab == prefab and slot 
    end)
end


function EntUtil:CanPutInItem(cont, item)
    local container = self:GetContainer(cont)
    if container and self:IsValid(item) then
        local numslots = container:GetNumSlots()
        local prefab = item.prefab
        local slot
        
        if container:AcceptsStacks() then
            for i = 1, numslots do
                local item_slot = container:GetItemInSlot(i)
                slot = item_slot and item_slot.prefab == prefab and item_slot.skinname == item.skinname and self:GetStackSize(item_slot) < self:GetMaxSize(item_slot) and i
                if slot then
                    return slot
                end
            end
        end
        
        for i = 1, numslots do
            slot = not container:GetItemInSlot(i) and container:CanTakeItemInSlot(item, i) and i
            if slot then
                return slot
            end
        end
    end
end


function EntUtil:GetStackSize(ent)
    if ent and ent.components then
        local stackable = ent.components.stackable or (ent.replica and ent.replica.stackable)
        if stackable then
            return stackable:StackSize()
        end
    end
    return 1
end

function EntUtil:GetMaxSize(ent)
    if ent and ent.replica and ent.replica.stackable then
        return ent.replica.stackable:MaxSize()
    end
    return 1
end


function EntUtil:GetAtlasAndImage(ent)
    local item = ent and ent.replica and ent.replica.inventoryitem
    if item then
        local prefab = ent.prefab
        local ex_str = prefab and prefab:match("(.*)_spice_")
        local tex = ex_str and ex_str .. ".tex"
        local xml = tex and GetInventoryItemAtlas(tex)
        if xml and tex then
            return xml, tex
        end
        return item:GetAtlas(), item:GetImage()
    end
end



local function HasSpoilage(item)
    if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        return false
    elseif item:HasTag("show_spoilage") then
        return true
    else
        return t_util:GetElement(FOODTYPE or {}, function(tp)
            return item:HasTag("edible_"..tp) 
        end)
    end
end
function EntUtil:GetPercent(inst)
    local i = 100
    local classified = t_util:GetRecur(inst, "replica.inventoryitem.classified")
    if classified then
        if classified.perish and HasSpoilage(inst) then
            
            i = math.floor(classified.perish:value() / .62)
        elseif classified.percentused then
            
            i = classified.percentused:value()
            
            if i == 255 then
                return 100
            end
        end
    end
    return i
end




function EntUtil:GetTags(ent, isclone)
    if isclone and ent.prefab then
        return self:ClonePrefab(ent.prefab).tags
    else
        local tags = {}
        local debugstring = ent and ent.entity:GetDebugString()
        if type(debugstring) == "string" then
            local tags_string = debugstring:match("Tags:(.-)\n")
            tags = tags_string and tags_string:split(" ") or {}
        end
        return t_util:IPairFilter(tags, function(tag)
            return tag ~= "FROMNUM" and tag
        end)
    end
end


local PrefabsBug = {
   wx78_backupbody = true, 
}
function EntUtil:ClonePrefab(prefab)
    if type(prefab) ~= "string" or not TheWorld or not Prefabs[prefab] or PrefabsBug[prefab] then
        return {
            components = {},
            prefab = prefab,
            tags = {},
            name = self.NullName
        }
    end
    if not Mod_ShroomMilk.PrefabCopy[prefab] then
        Mod_ShroomMilk.PrefabCopy[prefab] = {
            components = {},
            prefab = prefab,
            tags = {},
            name = self.NullName
        }
        MOD_SRM_LOCK = true
        local IsMasterSim = TheWorld.ismastersim
        getmetatable(TheWorld).GetPocketDimensionContainer = getmetatable(TheWorld).GetPocketDimensionContainer or function() end
        TheWorld.ismastersim = true
        local success, prefab_copy = pcall(SpawnPrefab, prefab)
        if success then
            local coms = prefab_copy and prefab_copy.components
            t_util:Pairs(coms or {}, function(k, v)
                Mod_ShroomMilk.PrefabCopy[prefab].components[k] = v
            end)
            Mod_ShroomMilk.PrefabCopy[prefab].tags = self:GetTags(prefab_copy)
            Mod_ShroomMilk.PrefabCopy[prefab].name = self:GetPrefabName(prefab, prefab_copy) or self.NullName
            if prefab_copy then
                prefab_copy:Remove()
            end
        end
        TheWorld.ismastersim = IsMasterSim
        MOD_SRM_LOCK = false
        if not success then
            print("[群鸟绘卷] ClonePrefab Error:", prefab, ret)
        end
    end
    return Mod_ShroomMilk.PrefabCopy[prefab]
end


function EntUtil:IsAnim(anim, ent)
    if self:IsValid(ent) and ent.AnimState then
        local t = type(anim)
        if t == "table" then
            return t_util:IGetElement(anim, function(anim_str)
                return ent.AnimState:IsCurrentAnimation(anim_str)
            end)
        elseif t == "string" then
            return ent.AnimState:IsCurrentAnimation(anim)
        elseif t == "function" then
            local get_anim = self:GetAnim(ent)
            if get_anim then
                return anim(get_anim)
            end
        end
    end
end

function EntUtil:TileEnts(core_ent, prefab, allowTags, banTags, allowAnims, banAnims, func)
    local pos = type(core_ent) == "table" and core_ent.x and core_ent.z and core_ent
    if not pos then
        local core = self:IsValid(core_ent) and core_ent or ThePlayer
        pos = core and core:GetPosition()
    end
    local r_ents = {}
    if pos and TheWorld and TheWorld.Map then
        
        banTags = type(banTags) == "table" and banTags or { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' }
        r_ents = t_util:IPairFilter(TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x, 0, pos.z), function(ent)
            if (not prefab or prefab == ent.prefab or (type(prefab) == "table" and table.contains(prefab, ent.prefab)))
                and (not allowTags or ent:HasTags(allowTags))
                and not ent:HasOneOfTags(banTags)
                and (not allowAnims or self:IsAnim(allowAnims, ent))
                and (banAnims and not self:IsAnim(banAnims, ent) or not IsEntityDead(ent))
                and (not func or func(ent))
            then
                return ent
            end
        end)
    end
    return r_ents
end


function EntUtil:FindEnts(core_ent, prefab, range, allowTags, banTags, allowAnims, banAnims, func)
    local pos = type(core_ent) == "table" and core_ent.x and core_ent.z and core_ent
    if not pos then
        local core = self:IsValid(core_ent) and core_ent or ThePlayer
        pos = core and core:GetPosition()
    end
    local r_ents = {}
    if pos then
        local ents = TheSim:FindEntities(pos.x, 0, pos.z,
            type(range) == "number" and range or 80,
            type(allowTags) == "table" and allowTags or nil,
            type(banTags) == "table" and banTags or { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' }
        )
        for _, ent in ipairs(ents) do
            if (not prefab or prefab == ent.prefab or (type(prefab) == "table" and table.contains(prefab, ent.prefab)))
                and (not allowAnims or self:IsAnim(allowAnims, ent))
                and (banAnims and not self:IsAnim(banAnims, ent) or not IsEntityDead(ent))
                and (not func or func(ent))
            then
                table.insert(r_ents, ent)
            end
        end
    end
    return r_ents
end


function EntUtil:FindEnt(core_ent, prefab, range, allowTags, banTags, allowAnims, banAnims, func)
    local pos = type(core_ent) == "table" and core_ent.x and core_ent.z and core_ent
    if not pos then
        local core = self:IsValid(core_ent) and core_ent or ThePlayer
        pos = core and core:GetPosition()
    end
    if not pos then return end
    local ents = TheSim:FindEntities(pos.x, 0, pos.z,
        type(range) == "number" and range or 64,
        (type(allowTags) == "string" and {allowTags}) or (type(allowTags) == "table" and allowTags) or nil,
        type(banTags) == "table" and banTags or { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' }
    )
    for _, ent in ipairs(ents) do
        if (not prefab or prefab == ent.prefab or (type(prefab) == "table" and table.contains(prefab, ent.prefab)))
            and (not allowAnims or self:IsAnim(allowAnims, ent))
            and (banAnims and not self:IsAnim(banAnims, ent) or not IsEntityDead(ent))
            and (not func or func(ent))
        then
            return ent
        end
    end
end


function EntUtil:FindEntLoc(core_ent, tags)
    local trans = self:IsValid(core_ent)
    if trans then
        local x, y, z = trans:GetWorldPosition()
        return TheSim:FindEntities(x, 0, z, 0.01, tags)[1]
    end
end


function EntUtil:SetBindEvent(ent, eventname, func)
    if not (ent and ent.prefab) then return end     
    ent:RemoveEventCallback(eventname, func)
    ent:ListenForEvent(eventname, func)
end


function EntUtil:GetAnim(ent)
    if ent and ent.AnimState then
        local bank, anim, frame = ent.AnimState:GetHistoryData()
        return anim
    end
end


function EntUtil:GetFrame(ent)
    if ent and ent.AnimState then
        local bank, anim, frame = ent.AnimState:GetHistoryData()
        return frame
    end
end



function EntUtil:GetAngle(ent) 
    local tags_string = self:IsValid(ent) and ent.entity:GetDebugString()
    local heading = tonumber(tags_string and tags_string:match(" Heading=(.-) Prediction"))
    return heading and -heading
end



function EntUtil:GetAngleToTarget(ent, target)
    if self:IsValid(target) then
        local heading = self:GetAngle(ent)
        if heading then
            return c_util:GetAngleDiff(heading, c_util:GetAngle(ent:GetPosition(), target:GetPosition()))
        end
    end
end


function EntUtil:GetAngleWithTarget(ent, target)
    local a, b = self:IsValid(ent), self:IsValid(target)
    if a and b then
        local x1, _, z1 = a:GetWorldPosition()
        local x2, _, z2 = b:GetWorldPosition()
         
        local dx, dz = x2 - x1, z2 - z1
        
        local angleRad = math.atan2(dz, dx)
        
        angleRad = math.deg(angleRad)
        return c_util:GetAngleDiff(angleRad, 0)
    end
end


function EntUtil:GetDist(e1, e2)
    if not self:IsValid(e2) then
        e2 = ThePlayer
    end
    if self:IsValid(e1) and self:IsValid(e2) then
        local p1 = e1:GetPosition()
        local p2 = e2:GetPosition()
        return c_util:GetDist(p1.x, p1.z, p2.x, p2.z)
    end
end


function EntUtil:GetRadius(ent, default)
    return ent and ent.GetPhysicsRadius and ent:GetPhysicsRadius(default or 0)
end


local function GetStrPrefab(prefab)
    return STRINGS.NAMES[prefab:upper()]
end
function EntUtil:GetPrefabName(prefab, ent)
    if type(prefab) ~= "string" then
        return self.NullName
    end
    local name = PrefabNames[prefab]
    if not name then
        name = GetStrPrefab(prefab)
        
        if name and prefab:sub(-6)=="_seeds" then
            name = GetStrPrefab("known_"..prefab) or name
        end
        
        if not name and prefab:sub(1, 10) == "transmute_" then
            name = GetStrPrefab(prefab:sub(11))
        end
        
        if not name and prefab:sub(-10) == "_blueprint" then
            name = GetStrPrefab(prefab:sub(1, prefab:len()-10))
            name = name and subfmt(GetStrPrefab("BLUEPRINT_RARE"), {item=name})
        end
        
        if not name and prefab:sub(-7) == "_sketch" then
            name = GetStrPrefab(prefab:sub(1, prefab:len()-7))
            name = name and subfmt(GetStrPrefab("SKETCH"), {item=name})
        end
        
        if not name and prefab:sub(1, 11) == "chesspiece_" then
            local num_last = prefab:find("_stone") or prefab:find("_moonglass") or prefab:find("_marble")
            name = num_last and GetStrPrefab(prefab:sub(1, num_last-1))
        end
        
        if not name and prefab:sub(-6)=="_waxed" then
            local obj = t_util:GetRecur(STRINGS, "UI.HUD.WAXED")
            local main = GetStrPrefab(prefab:sub(1, -7))
            name = obj and main and subfmt("{obj}{main}", {obj = obj, main = main})
        end

        if not name and prefab:sub(-8) == "_spawner" then
            name = GetStrPrefab(prefab:sub(1, prefab:len()-8))
            name = name and name..(t_util:GetRecur(STRINGS, "UI.CUSTOMIZATIONSCREEN.START_LOCATION") or "出生点")
        end
        if not name and prefab:sub(-7) == "spawner" then
            name = GetStrPrefab(prefab:sub(1, prefab:len()-7))
            name = name and name..(t_util:GetRecur(STRINGS, "UI.CUSTOMIZATIONSCREEN.START_LOCATION") or "出生点")
        end
        if not name and prefab:sub(-5) == "_item" then
            name = GetStrPrefab(prefab:sub(1, prefab:len()-5))
        end
        if not name then
            local skinname = GetSkinName(prefab)
            name = STRINGS.SKIN_NAMES.missing ~= skinname and skinname
        end
        if not name then
            local spice_start = prefab:find("_spice_")
            if spice_start then
                local base_prefab = prefab:sub(1, spice_start - 1)
                local base_name = GetStrPrefab(base_prefab)
                if base_name then
                    local spice_prefab = prefab:sub(spice_start + 1)
                    local spice_name = GetStrPrefab(spice_prefab.."_FOOD")
                    name = spice_name and subfmt(spice_name, {food = base_name})
                end
            end
        end
        PrefabNames[prefab] = type(name) == "string" and name or self.NullName
    end
    if ent then
        name = name or ent:GetBasicDisplayName()
        name = name == "MISSING NAME" and prefab or name
    end
    return name or self.NullName
end


function EntUtil:GetItemEquipSlot(item)
    return item and item.replica and item.replica.equippable and item.replica.equippable:EquipSlot()
end


function EntUtil:IsLightSourceEquip(item)
    return item and self:GetItemEquipSlot(item) and
    (item:HasOneOfTags({ "light", "fire", "lighter", "cave_fueled", "wormlight_fueled" })
        or table.contains({ "lunarplanthat", "yellowamulet", "nightstick", "hat_lichen" }, item.prefab))
end


function EntUtil:GetNextEntWithPrefab(ents, prefab, reverse)
    local prefab_ents = {}
    t_util:Pairs(ents, function(_, ent)
        local prefab = ent.prefab
        if prefab then
            prefab_ents[prefab] = ent
        end
    end)
    local nextprefab = t_util:GetNextLoopKey(prefab_ents, prefab, reverse)
    return nextprefab and prefab_ents[nextprefab]
end


function EntUtil:GetCombatTarget(ent)
    return self:IsValid(ent) and ent.replica and ent.replica.combat and ent.replica.combat:GetTarget()
end


function EntUtil:GetLeaderTarget(ent)
    return self:IsValid(ent) and ent.replica and ent.replica.follower and ent.replica.follower:GetLeader()
end




function EntUtil:WaitToDo(ent, interval, num, func_if, func_succ, func_fail)
    ent = ent or TheGlobalInstance
    local count = 0
    local function countToDo()
        count = count + 1
        if (count > num or not self:IsValid(ent)) and type(func_fail) == "function" then
            func_fail()
        else
            ent:DoTaskInTime(interval, function()
                local value
                if type(func_if) == "function" then
                    value = func_if(ent)
                else
                    value = func_if
                end
                if value then
                    if type(func_succ) == "function" then
                        func_succ(value, count)
                    end
                else
                    countToDo()
                end
            end)
        end
    end
    countToDo()
end

function EntUtil:SpawnFx(hxname, build, bank, anim, color, scale)
    scale = scale or 1
    local inst = self:SpawnNull()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBuild(build)
    inst.AnimState:SetBank(bank)
    inst.AnimState:PlayAnimation(anim, true)
    inst.AnimState:SetScale(scale, scale, scale)
    if color then
        inst.AnimState:SetMultColour(unpack(color))
    end
    inst:AddTag("FX")
    inst.hxname = hxname
    return inst
end

function EntUtil:SpawnNull()
    local inst = CreateEntity()
    inst:AddTag("huxi")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")
    inst.persists = false
    return inst
end



function EntUtil:SetHighlight(ent, bool)
    if ent and ent.AnimState then
        local light = bool and 1 or 0
        ent.AnimState:SetLightOverride(light)
        t_util:Pairs(ent.children or {}, function (child)
            if child and child.AnimState then
                child.AnimState:SetLightOverride(light)
            end
        end)
    end
    return ent
end


function EntUtil:HasOneOfComps(ent, comps)
    local comps = type(comps) == "table" and comps or {comps}
    return t_util:IGetElement(comps, function(comp)
        return ent:HasActionComponent(comp)
    end)
end



local prefab_sc, prefab_chester = "shadow_container", "cont_chester"
local prefabs_shadow = {prefab_sc, "magician_chest"}

local prefabs_chester = {"chester", "hutch"}

local prefabs_movable = {
    woby = {"wobysmall", "wobybig"}
}


function EntUtil:IsShadowContainer(ent)
    local prefab = ent and ent.prefab
    if prefab then
        if table.contains(prefabs_shadow, prefab) then
            return prefab_sc
        elseif ent._chesterstate then
            return (ent._chesterstate:value() == 3) and prefab_sc
        end
    end
end

function EntUtil:IsMovableContainer(ent)
    local prefab = ent and ent.prefab
    if prefab then
        if table.contains(prefabs_chester, prefab) then
            return prefab_chester
        else
            return t_util:GetElement(prefabs_movable, function(prefab_movable, prefabs)
                return table.contains(prefabs, prefab) and prefab_movable
            end)
        end
    end
end


function EntUtil:IsContainer(ent)
    if not ent then return end
    return (ent.replica and ent.replica.container) or ent.prefab=="magician_chest"
end

function EntUtil:IsAnyContainer(ent)
    return self:IsContainer(ent) or self:IsMovableContainer(ent) or self:IsShadowContainer(ent)
end

function EntUtil:Mod_Showme_Has(ent, prefab)
    return ent.ShowMe_chest_table and t_util:GetElement(ent.ShowMe_chest_table, function(_prefab)
        return _prefab:gsub(" ", "") == prefab and ent
    end)
end
function EntUtil:Mod_Insight_Has(ent, prefab)
    if self:IsContainer(ent) then
        local ins = t_util:GetRecur(ThePlayer, "replica.insight")
        return ins and ins:ContainerHas(ent, prefab, false) and ent
    end
end

function EntUtil:Hook_Say(ent, func)
    local _Say = t_util:GetRecur(ent, "components.talker.Say")
    if _Say then
        ent.components.talker.Say = function(self, str_say, ...)
            str_say = func(str_say) or str_say
            return _Say(self, str_say, ...)
        end
    end
end


function EntUtil:OnPlayerScreen(ent)
    if t_util:GetRecur(ent, "entity.FrustumCheck") then
        return ent.entity:FrustumCheck() or ent:HasTag("INLIMBO")
    end
end







function EntUtil:Debug(ent)
    if not self:IsValid(ent) then return end
    ent._harrow = ent:SpawnChild("harrow")
    ent._harrow.Transform:SetScale(2, 2, 2)
    ent._harrow.Transform:SetRotation(-90)
    
    
end

function EntUtil:AddMoonFx(ent)
    if not self:IsValid(ent) then return end
    local pos = ent:GetPosition()
    local fx = SpawnPrefab("boatrace_fireworks")
    fx.Transform:SetPosition(pos.x, 0, pos.z)
    fx:DoTaskInTime(3, function(fx)
        fx:Remove()
    end)
    local _fx = SpawnPrefab("moonpulse")
    _fx.Transform:SetPosition(pos.x, 0, pos.z)
    _fx:DoTaskInTime(3, function(fx)
        _fx:Remove()
    end)
end

function EntUtil:DebugGoTo()
    local trans = self:IsValid(t_util.ent)
    if trans then
        local x,_,z = trans:GetWorldPosition()
        i_util:GoTo(x, z)
    end
end







function EntUtil:GetPosID(ent)
    
    local prefab = ent and ent.prefab
    if prefab then
        if self:IsShadowContainer(ent) then
            return prefab_sc
        elseif table.contains(prefabs_chester, prefab) then
            return prefab_chester
        end
    end
    local trans = self:IsValid(ent)
    if trans then
        if ent == ThePlayer then
            return "theplayer"
        elseif ent:HasTag("inlimbo") then
            
            
        else
            
            local x, y, z = trans:GetWorldPosition()
            return c_util:GetPosID(x, z)
        end
    end
end

return EntUtil
