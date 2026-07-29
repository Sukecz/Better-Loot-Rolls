local addonName, ns = ...

local Core = {}
ns.Core = Core

local eventFrame = CreateFrame("Frame")

local function Print(message)
    print("|cff33ff99Better Loot Rolls:|r " .. tostring(message))
end

local function PrintWelcome(message)
    print("|cff33ff99Better Loot Rolls|r " .. tostring(message))
end

function Core:Refresh()
    ns.RollTracker:Refresh()
end

function Core:ShowWelcome()
    PrintWelcome(ns.L.WELCOME_MESSAGE)
end

function Core:Show()
    ns.MainWindow:Show()
    self:Refresh()
end

function Core:Hide()
    ns.MainWindow:Hide()
end

function Core:Toggle()
    if ns.MainWindow:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function Core:Initialize()
    if self.initialized then
        return
    end

    ns.Database:Initialize()

    if not ns.ApiCompat:IsSupported() then
        Print(ns.L.UNSUPPORTED)
        return
    end

    ns.MainWindow:Initialize()
    ns.Options:Initialize()
    ns.SlashCommands:Initialize()
    ns.RollTracker:SetChangedCallback(function()
        ns.MainWindow:Refresh()
    end)

    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("LOOT_HISTORY_FULL_UPDATE")
    eventFrame:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED")
    eventFrame:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE")
    eventFrame:RegisterEvent("LOOT_HISTORY_AUTO_SHOW")

    self.initialized = true
end

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            self:Initialize()
        end
        return
    end

    if not self.initialized then
        return
    end

    if event == "PLAYER_LOGIN" then
        self:Refresh()
        self:ShowWelcome()
    elseif event == "LOOT_HISTORY_AUTO_SHOW" then
        self:Refresh()
        if ns.Database:Get("autoShow") then
            ns.MainWindow:Show()
        end
    else
        self:Refresh()
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    Core:OnEvent(event, ...)
end)
