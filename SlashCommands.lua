local _, ns = ...

local SlashCommands = {}
ns.SlashCommands = SlashCommands

local function Print(message)
    print("|cff33ff99Better Loot Rolls:|r " .. tostring(message))
end

function SlashCommands:Handle(input)
    input = string.lower((input or ""):match("^%s*(.-)%s*$"))
    local command, argument = input:match("^(%S+)%s*(.-)$")

    if not command or command == "" or command == "toggle" then
        ns.Core:Toggle()
    elseif command == "show" then
        ns.Core:Show()
    elseif command == "hide" then
        ns.Core:Hide()
    elseif command == "options" or command == "config" then
        ns.Options:Show()
    elseif command == "history" then
        local limit = tonumber(argument)
        if not limit then
            Print(ns.L.USAGE)
            return
        end
        ns.Database:Set("historyLimit", limit)
        ns.Database:PruneHistory()
        ns.MainWindow:Refresh()
        Print(string.format(ns.L.HISTORY_SET, ns.Database:Get("historyLimit")))
    elseif command == "clear" then
        ns.Database:ClearHistory()
        ns.MainWindow:Refresh()
        Print(ns.L.HISTORY_CLEARED)
    elseif command == "reset" then
        ns.Database:ResetWindow()
        ns.MainWindow:ApplySettings()
    elseif command == "api" then
        Print(ns.ApiCompat:GetClientReport())
    else
        Print(ns.L.USAGE)
    end
end

function SlashCommands:Initialize()
    SLASH_BETTERLOOTROLLS1 = "/betterlootrolls"
    SLASH_BETTERLOOTROLLS2 = "/blr"
    SlashCmdList.BETTERLOOTROLLS = function(input)
        self:Handle(input)
    end
end
