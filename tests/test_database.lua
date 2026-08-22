local ns = {}

assert(loadfile("Defaults.lua"))("BetterLootRolls", ns)
assert(loadfile("Database.lua"))("BetterLootRolls", ns)

BetterLootRollsDB = {
    schemaVersion = 5,
    settings = {
        historyLimit = 999,
        scale = "invalid",
        width = 10,
        height = 9999,
        autoShow = false,
        windowShown = true,
    },
    histories = {
        ["Mage-TestRealm"] = {},
    },
}

for index = 1, 110 do
    BetterLootRollsDB.histories["Mage-TestRealm"][index] = { rollID = index }
end

ns.Database:Initialize("Mage-TestRealm")

assert(ns.Database:Get("historyLimit") == 100)
assert(ns.Database:Get("scale") == 1)
assert(ns.Database:Get("opacity") == 1)
assert(ns.Database:Get("width") == 140)
assert(ns.Database:Get("height") == 800)
assert(ns.Database:Get("autoShow") == false)
assert(ns.Database:Get("windowShown") == true)
assert(#ns.Database:GetHistory() == 100)

ns.Database:Set("historyLimit", 5)
assert(#ns.Database:GetHistory() == 5)

local record = { fingerprint = "unique" }
assert(ns.Database:AddCompleted(record) == true)
assert(ns.Database:AddCompleted(record) == false)

assert(ns.Database:SetCharacterKey("Rogue-TestRealm") == true)
assert(#ns.Database:GetHistory() == 0)
assert(ns.Database:AddCompleted({ fingerprint = "rogue" }) == true)
assert(#ns.Database:GetHistory() == 1)
ns.Database:ClearHistory()
assert(#ns.Database:GetHistory() == 0)
ns.Database:SetCharacterKey("Mage-TestRealm")
assert(#ns.Database:GetHistory() == 5)

BetterLootRollsDB = {
    schemaVersion = 1,
    settings = {
        historyLimit = 20,
        autoShow = true,
        scale = 1,
        width = 460,
        height = 360,
        welcomeShown = true,
    },
    history = {
        { fingerprint = "old-account-wide-record" },
    },
}
ns.Database:Initialize("Mage-TestRealm")
assert(BetterLootRollsDB.schemaVersion == 5)
assert(ns.Database:Get("width") == 300)
assert(ns.Database:Get("height") == 240)
assert(ns.Database:Get("opacity") == 1)
assert(ns.Database:Get("windowShown") == false)
assert(BetterLootRollsDB.settings.welcomeShown == nil)
assert(BetterLootRollsDB.history == nil)
assert(#BetterLootRollsDB.histories.__legacyAccountWide == 1)
assert(#ns.Database:GetHistory() == 0)

assert(ns.Database:SetCharacterKey(nil) == false)
assert(#ns.Database:GetHistory() == 0)

print("test_database.lua: ok")
