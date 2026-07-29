local messages = {}
local originalPrint = print
local settings = {
    welcomeShown = false,
}

print = function(message)
    messages[#messages + 1] = message
end

CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

local ns = {
    Database = {
        Get = function(_, key)
            return settings[key]
        end,
        Set = function(_, key, value)
            settings[key] = value
        end,
    },
    L = {
        WELCOME_MESSAGE = "is ready. Type /blr options to customize.",
    },
}

assert(loadfile("Core.lua"))("BetterLootRolls", ns)

assert(ns.Core:ShowWelcomeIfNeeded())
assert(settings.welcomeShown == true)
assert(#messages == 1)
assert(string.find(messages[1], "Better Loot Rolls", 1, true))
assert(string.find(messages[1], "/blr options", 1, true))

assert(not ns.Core:ShowWelcomeIfNeeded())
assert(#messages == 1)

print = originalPrint
print("test_welcome.lua: ok")
