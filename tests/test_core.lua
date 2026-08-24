local eventFrame
CreateFrame = function()
    eventFrame = {
        events = {},
        RegisterEvent = function(self, event)
            self.events[event] = true
        end,
        SetScript = function(self, script, callback)
            self[script] = callback
        end,
    }
    return eventFrame
end

local initializedCharacter
local selectedCharacter
local windowShown = true
local showCount = 0
local refreshCount = 0
local windowRefreshCount = 0
local ns = {
    L = {
        WELCOME_MESSAGE = "is ready.",
    },
    ApiCompat = {
        GetPlayerKey = function()
            return "Mage-TestRealm"
        end,
        IsSupported = function()
            return true
        end,
    },
    Database = {
        Initialize = function(_, characterKey)
            initializedCharacter = characterKey
        end,
        SetCharacterKey = function(_, characterKey)
            selectedCharacter = characterKey
        end,
        Get = function(_, key)
            assert(key == "windowShown")
            return windowShown
        end,
    },
    MainWindow = {
        Initialize = function() end,
        Refresh = function()
            windowRefreshCount = windowRefreshCount + 1
        end,
        Show = function()
            showCount = showCount + 1
        end,
    },
    Options = {
        Initialize = function() end,
    },
    SlashCommands = {
        Initialize = function() end,
    },
    RollTracker = {
        SetChangedCallback = function() end,
        Refresh = function()
            refreshCount = refreshCount + 1
        end,
    },
}

assert(loadfile("Core.lua"))("BetterLootRolls", ns)
ns.Core:OnEvent("ADDON_LOADED", "BetterLootRolls")
assert(initializedCharacter == "Mage-TestRealm")
assert(eventFrame.events.PLAYER_LOGIN == true)
assert(eventFrame.events.GET_ITEM_INFO_RECEIVED == true)

ns.Core:OnEvent("GET_ITEM_INFO_RECEIVED", 19019, true)
assert(windowRefreshCount == 1)
assert(refreshCount == 0)

ns.Core:OnEvent("GET_ITEM_INFO_RECEIVED", 19019, false)
assert(windowRefreshCount == 1)
assert(refreshCount == 0)

ns.Core:OnEvent("PLAYER_LOGIN")
assert(selectedCharacter == "Mage-TestRealm")
assert(refreshCount == 1)
assert(showCount == 1)

windowShown = false
ns.Core:OnEvent("PLAYER_LOGIN")
assert(refreshCount == 2)
assert(showCount == 1)

print("test_core.lua: ok")
