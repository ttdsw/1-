
local playerhud = require "screens/playerhud"
local save_id, string_brain = "sw_brain", "记忆力+"
local id_box_info = "_huxi_box_info"
local default_data = {
    box_preview = false,
    sign_more = false,
    chester_range = 36,
    color_item = "绿色",
    color_full = "紫色",
    force_memory = false,
    nightlight = true
}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local m_data = {
    brain_save = m_util:IsTurnOn("brain_save"),
    brain_sign = m_util:IsTurnOn("brain_sign"),
    brain_bundle = m_util:IsTurnOn("brain_bundle"),
    brain_chester = m_util:IsTurnOn("brain_chester")
}
local fn_moddata = function(id)
    return m_data[id]
end
local function ModSave(conf)
    return function(value)
        m_data[conf] = m_util:SaveModOneConfig(conf, value)
    end
end
local DataBox, id_box = {}, "box"
local DataInv, id_inv = {}, "inv"
local function BindBrainSave(net)
    local saver = TheWorld and TheWorld.components.hx_saver
    if saver then
        saver:Save()
    end
end
local function GetItemInfo(item)
    local xml, tex = e_util:GetAtlasAndImage(item)
    local max = e_util:GetMaxSize(item)
    return {
        prefab = item.prefab,
        stack = tostring(e_util:GetStackSize(item)),
        max = tostring(max > 4096 and 4097 or max),
        
        xml = h_util:ZipXml(xml),
        tex = tex
    }
end
local enable_smart_minisign

local bundle_info_id = "_huxi_bundle_info"
local bundle_prefabs = {"bundle", "gift"}
local BundleInfo = {
    info = nil,
    time = 0,
    prefabs = bundle_prefabs,
    id = bundle_info_id
}
i_util:AddPrefabsHook(BundleInfo)

local _bundle_lock 
local _OpenContainer = playerhud.OpenContainer
playerhud.OpenContainer = function(self, cont, side, ...)
    local container = e_util:GetContainer(cont)
    if container and cont:HasTag("bundle") and not _bundle_lock then
        local widget = container:GetWidget()
        local _fn = t_util:GetRecur(widget, "buttoninfo.fn")
        if _fn then
            _bundle_lock = true
            widget.buttoninfo.fn = function(ent, ...)
                container = e_util:GetContainer(ent)
                if container then
                    local items = container:GetItems() or {}
                    BundleInfo.info = {}
                    BundleInfo.time = GetTime()
                    local count = 0
                    t_util:Pairs(items, function(slot, item)
                        if item then
                            count = count + 1
                            BundleInfo.info[tostring(count)] = GetItemInfo(item)
                        end
                    end)
                    BundleInfo.info.num = tostring(count)
                end
                return _fn(ent, ...)
            end
        end
    end
    return _OpenContainer(self, cont, side, ...)
end
local function GetSBox()
    return h_util:GetControls().sbox
end
i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if m_data.brain_bundle then
        local item = item_inv or item_world
        if item then
            local data = item[bundle_info_id]
            if data then
                local sbox = GetSBox()
                if sbox then
                    if m_util:EnableShowme() or m_util:EnableInsight() then
                        return
                    end
                    if item_inv then
                        sbox:SetData(data, TheInput:GetScreenPosition(), true)
                    elseif item_world then
                        sbox:SetData(data, item_world:GetPosition())
                    end
                    return nil, function()
                        sbox:SetData()
                    end
                end
            end
        end
    end
end)

local items_highlight = {}

local function ClearHighlight()
    t_util:IPairs(items_highlight, function(ent)
        h_util.SetAddColor(ent)
        e_util:SetHighlight(ent, false)
    end)
    items_highlight = {}
end

local function AddHighlight(ent, color)
    h_util.SetAddColor(ent, color)
    e_util:SetHighlight(ent, save_data.nightlight)
    if ent then
        table.insert(items_highlight, ent)
    end
end
local function GetMemoryBoxData(ent)
    local pos_id = p_util:GetEntPosID(ent)
    return pos_id and (DataBox[pos_id] or DataInv[pos_id])
end


local function HasPrefabWithBox(ent, prefab, dontcheckbundle)
    if not e_util:IsAnyContainer(ent) then
        return
    end
    local data_cont = GetMemoryBoxData(ent)
    if not data_cont then
        return
    end
    local pos_id = p_util:GetEntPosID(ent)
    local has = t_util:GetElement(data_cont, function(slot, data)
        if type(data) ~= "table" then
            return
        end
        if data.prefab:find("^"..prefab.."%d?$") then
            return true
        end
        
        if not dontcheckbundle and table.contains(bundle_prefabs, data.prefab) then
            local line = DataInv[pos_id .. "_" .. slot]
            if line then
                return t_util:GetElement(line, function(slot, data)
                    return type(data) == "table" and data.prefab == prefab
                end)
            end
        end
    end)
    return has and data_cont
end
local function HighlightAPrefab(prefab)
    local count = 0
    
    t_util:IPairs(e_util:FindEnts(nil, nil, save_data.chester_range), function(ent)
        if ent.prefab == prefab then
            
            AddHighlight(ent, save_data.color_item)
            count = count + 1
        else
            local function AddBoxHighlight(color)
                AddHighlight(ent, color)
                AddHighlight(ent.huxi_sign, color)
                if enable_smart_minisign then
                    AddHighlight(e_util:FindEntLoc(ent, {"sign"}), color)
                end
                count = count + 1
            end
            if m_util:EnableShowme() and not save_data.force_memory then
                local has = ent.ShowMe_chest_table and t_util:GetElement(ent.ShowMe_chest_table, function(_prefab)
                    return _prefab:gsub(" ", "") == prefab
                end)
                if has then
                    AddBoxHighlight(save_data.color_item)
                end
            elseif m_util:EnableInsight() and not save_data.force_memory then
                if e_util:IsContainer(ent) then
                    local ins = t_util:GetRecur(ThePlayer, "replica.insight")
                    if ins and ins:ContainerHas(ent, prefab, false) then
                        AddBoxHighlight(save_data.color_item)
                    end
                end
            else
                local data_cont = HasPrefabWithBox(ent, prefab)
                if data_cont then
                    AddBoxHighlight(data_cont.full and save_data.color_full or save_data.color_item)
                end
            end
        end
    end)

    return count
end

local function HighlightPrefab(prefab)
    if not m_data.brain_chester or (m_util:EnableInsight() and not m_util:IsMilker()) then
        return
    end
    
    ClearHighlight()
    if not prefab then
        return
    end
    HighlightAPrefab(prefab)
end

Mod_ShroomMilk.Func.GetMemoryBoxData = GetMemoryBoxData
Mod_ShroomMilk.Func.HasPrefabWithBox = HasPrefabWithBox
Mod_ShroomMilk.Func.ClearHighlight = ClearHighlight
Mod_ShroomMilk.Func.HighlightPrefabs = function(prefabs)
    local count = 0
    if m_data.brain_chester then
        ClearHighlight()
        t_util:IPairs(type(prefabs) == "table" and prefabs or {prefabs}, function(prefab)
            count = count + HighlightAPrefab(prefab)
        end)
    end
    return count
end


AddPrefabPostInit("inventory_classified", function(inst)
    inst:ListenForEvent("activedirty", function(inst)
        local item = inst._active:value()
        HighlightPrefab(item and item.prefab)
    end)
end)
local pointer



local function ShowPrefabView(prefab, is_display)
    if not prefab then
        return
    end
    if is_display then
        pointer = prefab
    else
        if pointer == prefab then
            pointer = nil
        end
    end
    HighlightPrefab(pointer)
end
AddClassPostConstruct("widgets/ingredientui", function(self, ...)
    local _OnGainFocus, _OnLoseFocus = self.OnGainFocus, self.OnLoseFocus
    function self.OnGainFocus(...)
        ShowPrefabView(self.recipe_type, true)
        return _OnGainFocus(...)
    end

    function self.OnLoseFocus(...)
        ShowPrefabView(self.recipe_type, false)
        return _OnLoseFocus(...)
    end
end)

AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function(self, ...)
    local _OnGainFocus, _OnLoseFocus = self.OnGainFocus, self.OnLoseFocus
    function self.OnGainFocus(...)
        ShowPrefabView(self.recipe_name, true)
        return _OnGainFocus(...)
    end

    function self.OnLoseFocus(...)
        ShowPrefabView(self.recipe_name, false)
        return _OnLoseFocus(...)
    end
end)


local prefabs_minisign = {}
local prefabs_box_1 = {"treasurechest", 
"dragonflychest", 
"medal_livingroot_chest", 
"sora2chest_build_sora" 
}
local prefabs_box_2 = {"icebox", "saltbox"}
local prefabs_box_all = t_util:MergeList(prefabs_box_1, prefabs_box_2)
local function RefreshPrefabsMinisign()
    prefabs_minisign = t_util:MergeList(prefabs_box_1, save_data.sign_more and prefabs_box_2 or {})
end
RefreshPrefabsMinisign()
local seed_xml, seed_tex = h_util:GetPrefabAsset("seeds")
local enable_SeedImages = Mod_ShroomMilk.Setting.SeedImages
local function ShowSmartMinisign(cont)
    if not cont or enable_smart_minisign then
        return
    end
    if m_data.brain_sign and table.contains(prefabs_minisign, cont.prefab) then
        local id = p_util:GetEntPosID(cont)
        if not (cont.huxi_sign and cont.huxi_sign:IsValid()) then
            cont.huxi_sign = cont:SpawnChild("hminisign")
            if cont.prefab == "dragonflychest" then
                cont.huxi_sign.Transform:SetScale(1.2, 1.2, 1)
            end
        end
        local data = id and DataBox[id]
        if not (data and tonumber(data.num)) then
            return
        end

        local num = tonumber(data.num)
        local flag_draw
        for i = 1, num do
            local line = data[tostring(i)]
            if line then
                
                if enable_SeedImages and type(line.tex) == "string" and line.tex:find("_seeds.tex") then
                    cont.huxi_sign:Draw(seed_xml, seed_tex)
                else
                    cont.huxi_sign:Draw(h_util:ZipXml(line.xml, true), line.tex)
                end
                flag_draw = true
                break
            end
        end
        if not flag_draw then
            cont.huxi_sign:Draw()
        end
    elseif cont.huxi_sign then
        cont.huxi_sign:Remove()
        cont.huxi_sign = nil
    end
end
local function RefreshMinisigns()
    if m_util:IsHost() then
        t_util:Pairs(Ents, function(id, ent)
            ShowSmartMinisign(ent)
        end)
    else
        t_util:IPairs(e_util:FindEnts(nil, prefabs_box_all), ShowSmartMinisign)
    end
end
t_util:IPairs(prefabs_box_all, function(prefab_box)
    AddPrefabPostInit(prefab_box, function(box)
        box:DoTaskInTime(0, ShowSmartMinisign)
    end)
end)
i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if item_world and not p_util:GetActiveItem() then
        ClearHighlight()
    end
end)


local function SetBrainSave()
    local net = TheWorld and TheWorld.net
    if net then
        net:RemoveEventCallback("issavingdirty", BindBrainSave)
        if m_data.brain_save then
            net:ListenForEvent("issavingdirty", BindBrainSave)
        end
    end
end

i_util:AddSessionLoadFunc(function(saver, world, player, pusher)
    
    SetBrainSave()
    
    DataBox = saver:GetMap(id_box, true)
    DataInv = saver:GetMap(id_inv)
    
    enable_smart_minisign = TUNING.SMART_SIGN_DRAW_ENABLE
    
    
    local function LoadInvBox(item, cont, slot)
        local id_item_pos = p_util:GetEntPosID(item, cont, slot)
        local box_data = id_item_pos and DataInv[id_item_pos]
        if box_data then
            item[id_box_info] = box_data
        end
    end
    t_util:IPairs(p_util:GetSlotsFromAll(nil, nil, nil, "mouse") or {}, function(line)
        LoadInvBox(line.item, line.cont, line.slot)
    end)
    
    t_util:Pairs(p_util:GetEquips() or {}, function(slot, equip)
        LoadInvBox(equip, player, slot)
    end)
end)



local function RefreshBoxMemory(cont)
    local container = e_util:GetContainer(cont)
    if container then
        local ui_conts = h_util:GetControls().containers or {}
        local ui_cont = t_util:GetElement(ui_conts, function(_cont, ui_cont)
            return _cont == cont and ui_cont.inv and ui_cont
        end)
        
        if ui_cont then
            local numslots = #ui_cont.inv
            if numslots > 4 or cont:HasTag("inlimbo") then
                local id_cont_pos = p_util:GetEntPosID(cont)
                if id_cont_pos then
                    local inlimbo = cont:HasTag("inlimbo")
                    local boxdata = {
                        num = tostring(numslots),
                        pos = inlimbo and id_cont_pos or nil
                    }
                    local count = 0
                    t_util:Pairs(ui_cont.inv, function(i, slot)
                        local item = slot and slot.tile and slot.tile.item
                        if item then
                            boxdata[tostring(i)] = GetItemInfo(item) or nil
                            count = count + 1
                        end
                    end)
                    boxdata.full = count == container:GetNumSlots() and true or nil

                    cont[id_box_info] = boxdata

                    if inlimbo then
                        DataInv[id_cont_pos] = boxdata
                    else
                        DataBox[id_cont_pos] = boxdata
                    end
                    ShowSmartMinisign(cont)
                end
                
            end
        end
    end
end
Mod_ShroomMilk.Func.RefreshBoxMemory = RefreshBoxMemory
local _CloseContainer = playerhud.CloseContainer
playerhud.CloseContainer = function(self, cont, side, ...)
    RefreshBoxMemory(cont)
    return _CloseContainer(self, cont, side, ...)
end
local function RefreshInvBox(item, cont, slot)
    if item[id_box_info] then
        local _pos = item[id_box_info].pos
        if _pos then
            DataInv[_pos] = nil
        end
        local id_cont_pos = p_util:GetEntPosID(item, cont, slot)
        if id_cont_pos then
            item[id_box_info].pos = id_cont_pos
            DataInv[id_cont_pos] = item[id_box_info]
        end
    end
end

i_util:AddPlayerActivatedFunc(function(player, world, pusher)
    
    pusher:RegChanInv(RefreshInvBox)
    
    pusher:RegAddInv(function(cont, slot, item)
        RefreshInvBox(item, cont, slot)
    end)
end)

local function OpenBoxNotInlimBo(player)
    local ui_conts = t_util:GetRecur(player, "HUD.controls.containers") or {}
    return t_util:GetElement(ui_conts, function(cont)
        return not cont:HasTag("inlimbo") and cont
    end)
end
AddClassPostConstruct("widgets/controls", function(self, player)
    if self.sbox then
        self.sbox:Kill()
    end
    self.sbox = self:AddChild(require("widgets/huxi/huxi_box")())
end)

i_util:AddHoverOverFunc(function(str, player, item_inv, item_world)
    if not (item_world and save_data.box_preview) then
        return
    end
    local cont_shadow = e_util:IsShadowContainer(item_world)
    if e_util:GetContainer(item_world) or cont_shadow then
        local sbox = GetSBox()
        if sbox then
            local id_cont_pos = p_util:GetEntPosID(item_world)
            if id_cont_pos and DataBox then
                local cont_open = OpenBoxNotInlimBo(player)
                if cont_open and (cont_open == item_world or (e_util:IsShadowContainer(cont_open) and cont_shadow)) then
                    
                    sbox:SetData()
                else
                    sbox:SetData(DataBox[id_cont_pos], item_world:GetPosition())
                end
            end
            return nil, function()
                sbox:SetData()
            end
        end
    end
end)


local desc_add = "\n这是一个本地功能，别人打开了箱子后数据不会刷新"
local VData = require "data/valuetable"
local screen_data = {{
    id = "bilibili",
    prefab = "bilibili",
    type = "imgstr",
    label = "教程演示",
    hover = "点击查看视频教程或功能演示",
    fn = function()
        VisitURL("https://b23.tv/1DQ6nH8", true)
    end
}, {
    id = "brain_save",
    label = "天亮保存",
    hover = "如果你不经常回档或者崩溃，而且不喜欢天亮卡一下时\n可以关闭此选项",
    fn = function(value)
        ModSave("brain_save")(value)
        SetBrainSave()
    end,
    default = fn_moddata
}, {
    id = "box_preview",
    label = "箱子预览",
    hover = "鼠标移动到箱子上时预览里面的物品" .. desc_add,
    fn = fn_save("box_preview"),
    default = fn_get
}, {
    id = "brain_sign",
    label = "智能小木牌",
    hover = "打开过的箱子会有小木牌提示里面有什么" .. desc_add,
    fn = function(value)
        ModSave("brain_sign")(value)
        RefreshMinisigns()
    end,
    default = fn_moddata
}, {
    id = "sign_more",
    label = "冰箱小木牌",
    hover = "【智能小木牌】附属功能\n修改此设置，需要【重启游戏】后生效\n冰箱和盐盒是否显示小木牌",
    fn = function(value)
        fn_save("sign_more")(value)
        RefreshPrefabsMinisign()
        RefreshMinisigns()
    end,
    default = fn_get
}, {
    id = "brain_bundle",
    label = "打包纸记忆",
    hover = "亲手打包的东西会记得里面有什么",
    fn = ModSave("brain_bundle"),
    default = fn_moddata
}, {
    id = "brain_chester",
    label = "箱子物品高亮",
    hover = "鼠标拿起东西或者悬浮在配方上时，高亮物品和箱子。\n开启insight后该功能将禁用",
    fn = ModSave("brain_chester"),
    default = fn_moddata
}, {
    id = "chester_range",
    label = "检索范围：",
    hover = "【箱子物品高亮】附属功能\n检索高亮的范围, 越大越卡，但是范围会更大！",
    fn = fn_save("chester_range"),
    default = fn_get,
    type = "radio",
    data = t_util:BuildNumInsert(4, 80, 4, function(i)
        return {
            data = i,
            description = i
        }
    end)
}, {
    id = "color_item",
    label = "高亮颜色：",
    hover = "【箱子物品高亮】附属功能\n物品和箱子的高亮颜色",
    fn = fn_save("color_item"),
    default = fn_get,
    type = "radio",
    data = VData.RGB_datatable
}, {
    id = "color_full",
    label = "满载颜色：",
    hover = "【箱子物品高亮】附属功能\n【此功能在开启showme或ins时将被禁用】\n物品和箱子(满了)的高亮颜色",
    fn = fn_save("color_full"),
    default = fn_get,
    type = "radio",
    data = VData.RGB_datatable
}, {
    id = "nightlight",
    label = "夜光展示",
    hover = "是否在黑暗中也高亮显示",
    fn = fn_save("nightlight"),
    default = fn_get
}, {
    id = "force_memory",
    label = "强制本地记忆",
    hover = "慎重打开，打开后将不再和showme或ins交流!\n高亮等多个功能将完全本地控制显示！",
    fn = fn_save("force_memory"),
    default = fn_get
}}
local function fn()
    m_util:AddBindShowScreen({
        title = string_brain,
        id = save_id,
        icon = {{
            id = "add",
            prefab = "mods",
            hover = "数据可视化",
            fn = function()
                h_util:CreatePopupWithClose(nil, "尚未有人定制此功能，敬请期待。")
            end
        }},
        data = screen_data
    })()
    if m_util:EnableInsight() and not m_util:IsMilker() then
        h_util:CreatePopupWithClose("记忆力 · 提示",
            "您当前开启了insight, 高亮功能已禁用。")
        return
    end
    if not save_data.force_memory and (m_util:EnableInsight() or m_util:EnableShowme()) then
        h_util:CreatePopupWithClose("记忆力 · 提示",
            "您当前开启了insight或者showme, \n部分功能将会失效")
    end
    if enable_smart_minisign then
        h_util:CreatePopupWithClose("记忆力 · 提示",
            "您当前开启了服务器的【智能小木牌】，本地小木牌将自动禁用")
    end
end
m_util:AddBindIcon(string_brain, "icon_sanity", "记忆力 相关内容的设置", true, fn, nil, 10000)
