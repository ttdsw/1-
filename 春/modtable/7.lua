
local ImageButton = require "widgets/imagebutton"
local Popup = require "screens/redux/popupdialog"

AddClassPostConstruct("widgets/redux/worldsettings/worldsettingstab", function(self, index, c_screen)
    local pos = type(self.tabs) == "table" and self.tabs[#self.tabs] and self.tabs[#self.tabs]:GetPosition()
    local s_index, l_shards, slot = ShardSaveGameIndex, SERVER_LEVEL_SHARDS, c_screen and c_screen.save_slot
    if not (pos and s_index and l_shards and slot) then
        return
    end
    local shard = l_shards[index]

    local function makebtn(pos, str, cb)
        if self._hx_seed_btn then
            self._hx_seed_btn:Kill()
        end
        self._hx_seed_btn = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex",
            "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        local btn = self._hx_seed_btn
        btn:SetFont(CHATFONT)
        btn:SetScale(0.65)
        btn.text:SetColour(0, 0, 0, 1)
        btn:SetTextSize(30)
        btn:SetText(str)
        pos.x = pos.x + 250
        pos.y = pos.y + 5
        btn:SetPosition(pos)
        btn:SetOnClick(cb)
        return btn
    end

    if shard then
        local session = s_index:GetSlotSession(slot, shard)
        if session then
            local file = TheNet:GetWorldSessionFileInClusterSlot(slot, shard, session)
            if file then
                TheSim:GetPersistentStringInClusterSlot(slot, shard, file, function(load_success, str)
                    if load_success and str then
                        local success, savedata = RunInSandbox(str)
                        if success and savedata then
                            local seed = savedata.meta and savedata.meta.seed
                            if seed then
                                local function btnfn()
                                    local popup = Popup(Mod_ShroomMilk.Mod["春"].name,
                                        "通过种子生成世界的功能仍在开发中...\n\n 此世界种子:" ..
                                            seed .. "\n 此世界session:" .. session, {{
                                            text = "我知道了",
                                            cb = function()
                                                TheFrontEnd:PopScreen()
                                            end
                                        }}, nil, "big", "dark")
                                    TheFrontEnd:PushScreen(popup)
                                end
                                makebtn(pos, "地图种子:" .. seed, btnfn)
                            end
                        end
                    end
                end)
            end
        else
            
            
        end
    end
end)
