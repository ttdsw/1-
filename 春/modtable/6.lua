local ctitle = "群鸟绘卷 · 智能模组󰀏"
local errors_highlight = {"componentactions", "UnregisterComponentActions", "highlight"}
local function ModsGsub(text)
    local mods_name, text = {}, text or ""
    for match in string.gmatch(text, "/mods/([^/]+)/") do
        if not table.contains(mods_name, match) then
            table.insert(mods_name, match)
        end
    end
    t_util:IPairs(mods_name, function(modpath)
        local mod = KnownModIndex:GetModInfo(modpath)
        local name = mod and mod.name
        local version = mod and mod.version
        if name and version then
            text = string.gsub(text, modpath:gsub("[%(%)%.%%%+%-%*%?%[%]%{%}%%]", function(c)
                return "%" .. c
            end), modpath .. "【" .. name .. version .. "】")
        end
    end)

    return mods_name, text
end

AddClassPostConstruct("widgets/scripterrorwidget", function(self, title, text, buttons, texthalign, additionaltext, ...)
    
    local menu_children = self.menu and self.menu:GetChildren() or {}
    t_util:GetElement(menu_children, function(btn)
        if btn:GetText() == STRINGS.UI.MAINSCREEN.MODFORUMS then
            btn:SetOnClick(function()
                TheSim:OpenDocumentsFolder()
            end)
            btn.text:SetString("日志文件夹")
            return true
        end
    end)

    if self.text and self.title and self.additionaltext and text and title then

        local function isAssignmentError(errstrs)
            return not t_util:IGetElement(errstrs, function(fstr)
                return not text:rfind_plain(fstr)
            end)
        end
        
        if isAssignmentError(errors_highlight) then
            text =
                "这个错误是因为你开了相互冲突的服务器模组，导致主从不同步了。 \n\n\n" ..
                    text
            self.additionaltext:SetString("创意工坊搜索 擦屁股 订阅并启用即可修复！")
            self.additionaltext:SetSize(40)
        else
            self.additionaltext:SetString(
                "日志信息已生成，点击下方【日志文件夹】即可查看 ###_CRASH_### 文件！\n你启用了下列模组：\n" ..
                    additionaltext:gsub(STRINGS.UI.MAINSCREEN.SCRIPTERRORMODWARNING, ""))
        end

        
        local mods_name, text = ModsGsub(text)
        if #mods_name > 0 then
            self.text:SetString(text)
            self.title:SetString(ctitle)
        end
    end
end)

local function SaveError(str)
    local mods_name, str = ModsGsub(str)
    str =
        "\n下面的内容是玩家最后一次崩溃的客户端日志,\n请将此文件发给模组作者：\n\n\n" ..
            str .. "\n\n"
    str = str .. i_util:GetModsInfo()
    TheSim:SetPersistentString("../###_CRASH_###.txt", str)
end

local _DisplayError = DisplayError
function _G.DisplayError(e, ...)
    SaveError(e)
    return _DisplayError(e, ...)
end
