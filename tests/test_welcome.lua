local messages = {}
local originalPrint = print

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
    L = {
        WELCOME_MESSAGE = "is ready. Type /blr options to customize.",
    },
}

assert(loadfile("Core.lua"))("BetterLootRolls", ns)

ns.Core:ShowWelcome()
assert(#messages == 1)
assert(string.find(messages[1], "Better Loot Rolls", 1, true))
assert(string.find(messages[1], "/blr options", 1, true))

ns.Core:ShowWelcome()
assert(#messages == 2)

print = originalPrint
print("test_welcome.lua: ok")
