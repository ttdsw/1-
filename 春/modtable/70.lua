
local save_id, string_r = "sw_right", "右键加强"



local function GetScreenData()
    local screen_data = {
        title = "超级好用的 " .. string_r,
        id = save_id,
        data = {{
        id = "bilibili",
        prefab = "bilibili",
        type = "imgstr",
        label = "教程演示",
        hover = "点击查看视频教程或功能演示",
        fn = function()VisitURL("https://www.bilibili.com/video/BV1h2CrB5E6f/", true)end
    },},
    }
    local ui_data = screen_data.data
    t_util:IPairs(m_util:GetData("RIGHT"), function(data)
        table.insert(ui_data, {
            id = data.id,
            label = data.label,
            hover = data.hover,
            default = data.default,
            fn = data.fn,
        })
        if data.screen_data then
            table.insert(ui_data, {
                id = data.id.."_setting",
                label = "高级设置：",
                hover = "点击进入"..data.label.."的高级设置",
                default = data.label,
                type = "textbtn",
                fn = function()
                    m_util:PopShowScreen()
                    m_util:AddBindShowScreen({
                        title = data.label .. " 高级设置",
                        id = data.id.."_showscreen",
                        data = type(data.screen_data) == "function" and data.screen_data() or data.screen_data,
                    })()
                end
            })
        end
    end)

    return screen_data
end

m_util:AddBindShowScreen(save_id, string_r, "book_fossil", "右键 ".. h_util:GetStringKeyBoardMouse(MOUSEBUTTON_RIGHT) .. " 点击执行更多操作", function()
    m_util:AddBindShowScreen(GetScreenData())()
end, nil, 9993)