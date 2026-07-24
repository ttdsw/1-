local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local Text = require "widgets/text"
local c_util, e_util, h_util, m_util, t_util,p_util = 
require "util/calcutil",
require "util/entutil",
require "util/hudutil",
require "util/modutil",
require "util/tableutil",
require "util/playerutil"




local ECTRL = Class(Widget, function(self, inv, owner, meta, funcs, data)
    Widget._ctor(self, "ECTRL")
    
    meta = meta or {}
    self.Func = funcs
    self.Data = data
    
    
    
    
    
    
    
    
    
    
    
    self.a_pos = Vector3(496, 0, 0)
    self.img_size = 67
    self.img_space = 13
    self.img_a_space = self.img_size+self.img_space

    self.init_x = self.a_pos.x
    self.init_y = 2*self.img_a_space
    
    local init_x = meta.posx or self.init_x
    local init_y = meta.posy or self.init_y
    self:SetPosition(init_x, init_y)
    self:UI_Build(meta)
end)

function ECTRL:UI_Build(meta)
    if self.root then self.root:Kill() end
    if meta.sw ~= "on" then return end
    self.root = self:AddChild(Widget("ec_root"))
    local count_slot = 0
    local ui_slots = t_util:IPairFilter(self.Data.slots, function(slot)
        if meta["ui_"..slot] then
            count_slot = count_slot + 1
            return slot
        end
    end)
    
    local bg_width = count_slot*self.img_a_space
    local bg_height = self.img_a_space
    self.frame = self.root:AddChild(Widget("frame"))
    local function SetFrameThint(num)
        return function()
            
            t_util:Pairs(self.frame.sides:GetChildren() or {}, function(img)
                img:SetTint(1, 1, 1, num)
            end)
        end
    end
    self.frame:SetPosition(bg_width/2-self.img_a_space/2, bg_height/2-self.img_a_space/2)
    self.frame:SetHoverText(STRINGS.LMB.."可拖拽 \n黏着鼠标请按Esc", {offset_y = 1.5*self.img_size, colour = UICOLOURS.GOLD})
    h_util:ActivateUIDraggable(self, self.Func.SavePos, self.frame)
    
    local f_atlas = resolvefilepath(CRAFTING_ATLAS)
    
    
    
    local sides = self.frame:AddChild(Widget("sides"))
    sides:SetOnGainFocus(SetFrameThint(1))
    sides:SetOnLoseFocus(SetFrameThint(0))
    self.frame.sides = sides
    local left = sides:AddChild(Image(f_atlas, "side.tex"))
    local right = sides:AddChild(Image(f_atlas, "side.tex"))
    local top = sides:AddChild(Image(f_atlas, "top.tex"))
    local bottom = sides:AddChild(Image(f_atlas, "bottom.tex"))
    left:SetPosition(-bg_width / 2 - 15, 1)
    right:SetPosition(bg_width / 2 + 15, 1)
    top:SetPosition(0, bg_height / 2 + 10)
    bottom:SetPosition(0, -bg_height / 2 - 8)
    left:ScaleToSize(-26, -(bg_height - 20))
    right:ScaleToSize(26, bg_height - 20)
    top:ScaleToSize(bg_width+33, 38)
    bottom:ScaleToSize(bg_width+33, 38)
    
    local midstr = h_util:GetStringKeyBoardMouse(MOUSEBUTTON_MIDDLE) or STRINGS.RMB
    local hover_add = "\n"..STRINGS.LMB .. '擦除  ' .. midstr .. '切换'
    local init_xml, init_tex = "images/hud.xml", "slot_select.tex"
    for i,ui_slot in ipairs(ui_slots)do
        local item_slot = "item_"..ui_slot
        local btn_slot = "btn_"..ui_slot

        local btn = self.root:AddChild(Image(init_xml, init_tex))
        self[btn_slot] = btn
        h_util:ActivateBtnScale(btn, self.img_size)
        
        
        btn:SetPosition((i-1)*self.img_a_space, 0)
        local ui_data = self.Data.data_slots[ui_slot]
        local hover_text = ui_data.hover..(ui_data.hover_set and "\n"..ui_data.hover_set or hover_add)
        btn:SetHoverText(hover_text, {offset_y = 1.5*self.img_size})
        function btn:install(item)
            local xml, tex = e_util:GetAtlasAndImage(item)
            if not (xml and tex) and type(item)=="string" then
                xml, tex = e_util:GetAtlasAndImage(p_util:GetItemFromAll(item))
                if not (xml and tex) then
                    xml, tex = h_util:GetPrefabAsset(item)
                end
            end
            if xml then
                btn:SetTexture(xml, tex)
            else
                btn:SetTexture(init_xml, init_tex)
            end
            btn.preset_prefab = type(item) == "table" and item.prefab or item
        end
        local function InstallNext(reverse)
            return function()
                local prefab = meta[item_slot]
                local items = p_util:GetItemsFromAll(nil, nil, ui_data.filter, {"equip", "body", "backpack", "container", "mouse"}) or {}
                local item = e_util:GetNextEntWithPrefab(items, prefab, reverse)
                btn:install(item)
                prefab = item and item.prefab
                self.Func.SaveData(item_slot)(prefab)
                if ui_data.work then
                    ui_data.work()
                end
            end
        end
        h_util:BindMouseClick(btn, {
            [MOUSEBUTTON_LEFT] = function()
                if ui_data.ui_left then
                    ui_data.ui_left()
                else
                    local prefab = meta[item_slot]
                    if prefab then
                        btn:install()
                        prefab = false
                    else
                        local item = p_util:GetItemFromAll(nil, nil, ui_data.filter, {"equip", "body", "backpack", "container", "mouse"})
                        btn:install(item)
                        prefab = item and item.prefab
                    end
                    self.Func.SaveData(item_slot)(prefab)
                end
            end,
            [MOUSEBUTTON_RIGHT] = function()
                if ui_data.ui_right then
                    ui_data.ui_right()
                else
                    InstallNext()
                end
            end,
            [MOUSEBUTTON_SCROLLDOWN] = InstallNext(),
            [MOUSEBUTTON_SCROLLUP] = InstallNext(true),
        })
        btn:install(meta[item_slot])
    end
    SetFrameThint(0)()
end


function ECTRL:ResetPos()
    if self.frame then
        self.frame:StopFollowMouse()
        self:SetPosition(self.init_x, self.init_y)
        self.Func.SavePos({x = self.init_x, y = self.init_y})
    end
end


function ECTRL:ResetIcon()
    local btns = self.root and self.root:GetChildren() or {}
    t_util:Pairs(btns, function(btn)
        local prefab = btn.preset_prefab
        if prefab and btn.install then
            btn:install(prefab)
        end
    end)
end

return ECTRL