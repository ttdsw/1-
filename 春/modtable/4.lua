local silent = "hx_shutup/shroomcake_shutup/silent"
local save_id = "silent"
local save_data = s_mana:GetSettingLine(save_id, true)
local screen_data = {}
local noises = require("data/noisetable")
local function shutup_pets()
    t_util:Pairs(noises.pets, function(pet, pet_sounds)
        t_util:IPairs(pet_sounds, function(pet_sound)
            RemapSoundEvent(pet .. pet_sound, silent)
        end)
    end)
end

local function addfn(name, fn)
    table.insert(screen_data, {
        id = name,
        label = name,
        hover = "叉号:禁用噪音 对号：启用噪音\n该功能需要重启游戏才能生效！",
        default = function()
            return save_data[name]
        end,
        fn = function(right)
            save_data[name] = right and true or nil
            s_mana:SaveSettingLine(save_id, save_data)
        end
    })
    if not save_data[name] then
        fn()
    end
end

addfn("宠物", shutup_pets)

t_util:Pairs(noises.only, function(name, noises)
    local function fn()
        if type(noises) == "string" then
            RemapSoundEvent(noises, silent)
        else
            t_util:IPairs(noises, function(noise)
                RemapSoundEvent(noise, silent)
            end)
        end
    end
    addfn(name, fn)
end)

m_util:AddBindShowScreen("sw_shutup", "去除噪音", "phonograph", "该功能重启游戏后生效！", {
    title = "去除噪音",
    id = save_id,
    data = screen_data,
    default = function(id)
        return save_data[id] and true or false
    end,
    icon = {{
        id = "add",
        prefab = "mods",
        hover = "点击添加要去除噪音的实体！",
        fn = function()
            h_util:CreatePopupWithClose("去除噪音", "此功能尚未有人定制，无法自定义添加实体！")
        end
    }}
}, nil, -9998)
