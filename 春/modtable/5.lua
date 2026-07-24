local save_id, str_unlock = "sw_unlock", "本地指令"
local default_data = {}
local save_data, fn_get, fn_save = s_mana:InitLoad(save_id, default_data)
local function PlantRegistry()
    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
    local WEED_DEFS = require("prefabs/weed_defs").WEED_DEFS
    local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
    local TPR = ThePlantRegistry
    local function unLockPlant(defs)
        t_util:Pairs(defs, function(plant, data)
            local info = data.plantregistryinfo
            if type(info) == "table" then
                t_util:NumElement(#info, data, function(stage)
                    TPR:LearnPlantStage(plant, stage)
                end)
            end
        end)
    end
    local function UnLockFertilizer(defs)
        t_util:Pairs(defs, function(fertilizer)
            TPR:LearnFertilizer(fertilizer)
        end)
    end
    unLockPlant(PLANT_DEFS)
    unLockPlant(WEED_DEFS)
    UnLockFertilizer(FERTILIZER_DEFS)

    local pr = require "screens/plantregistrypopupscreen"
    TheFrontEnd:PushScreen(pr(ThePlayer))
end

local ismodder = m_util:IsHuxi()
local screen_data = {{
    id = "scrapbook",
    label = "图鉴解锁",
    fn = function()
        
        TheScrapbookPartitions:DebugSeenEverything()
        TheScrapbookPartitions:DebugUnlockEverything()
        m_util:PopShowScreen()
        h_util:PlaySound("learn_map")
    end,
    hover = "解锁全图鉴",
    default = true
}, {
    id = "plantregistry",
    label = "植物登记表解锁",
    fn = function()
        PlantRegistry()
        m_util:PopShowScreen()
        h_util:PlaySound("learn_map")
    end,
    hover = "园艺图鉴全解锁",
    default = true
}, {
    id = "skilltree",
    label = "技能树解锁",
    fn = function()
        require("debugcommands")
        d_resetskilltree()
        m_util:PopShowScreen()
        h_util:PlaySound("learn_map")
    end,
    hover = "重置并解锁本地全技能树\n解锁服务器的技能树请使用T键",
    default = true
}, {
    id = "i_am_modder",
    label = ismodder and "欢迎您，开发者！" or "开发者选项(禁用)",
    fn = function(_, btns)
        h_util:CreatePopupWithClose("开发者选项",
            ismodder and "警告：放弃权限后游戏将立即关闭！" or
                "警告：获取权限后游戏将立即关闭！\n 非模组作者请勿开启权限！", {{
                text = "取消"
            }, ismodder and {
                text = "确定关闭权限",
                cb = function()
                    s_mana:SaveSettingLine("i_am_modder", {})
                    btns.i_am_modder.labeltext:SetString("权限已关闭")
                    i_util:DoTaskInTime(3, function()
                        DoRestart(true)
                    end)
                end
            } or {
                text = "我已确认风险！",
                cb = function()
                    s_mana:SaveSettingLine("i_am_modder", {
                        ismodder = true
                    })
                    btns.i_am_modder.labeltext:SetString("已获取权限")
                    i_util:DoTaskInTime(3, function()
                        DoRestart(true)
                    end)
                end
            }})
    end,
    hover = "将开启模组测试环境，非必要请勿打开\n警告：非开发者请勿打开本功能！",
    default = function()
        return ismodder
    end
}}

m_util:AddBindShowScreen("sw_unlock", str_unlock, "blueprint_rare", "一些本地指令", {
    title = str_unlock,
    id = save_id,
    data = screen_data,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "更多功能",
        fn = function()
            h_util:CreatePopupWithClose(nil, "尚未有人定制如下功能：食谱（烹饪指南）全解锁")
        end
    }}
}, nil, 9996)

