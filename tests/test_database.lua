local ns = {}

assert(loadfile("Defaults.lua"))("BetterLootRolls", ns)
assert(loadfile("Database.lua"))("BetterLootRolls", ns)

BetterLootRollsDB = {
    settings = {
        historyLimit = 999,
        scale = "invalid",
        width = 10,
        height = 9999,
        autoShow = false,
    },
    history = {},
}

for index = 1, 110 do
    BetterLootRollsDB.history[index] = { rollID = index }
end

ns.Database:Initialize()

assert(ns.Database:Get("historyLimit") == 100)
assert(ns.Database:Get("scale") == 1)
assert(ns.Database:Get("opacity") == 1)
assert(ns.Database:Get("width") == 220)
assert(ns.Database:Get("height") == 800)
assert(ns.Database:Get("autoShow") == false)
assert(#ns.Database:GetHistory() == 100)

ns.Database:Set("historyLimit", 5)
assert(#ns.Database:GetHistory() == 5)

local record = { fingerprint = "unique" }
assert(ns.Database:AddCompleted(record) == true)
assert(ns.Database:AddCompleted(record) == false)

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
    history = {},
}
ns.Database:Initialize()
assert(BetterLootRollsDB.schemaVersion == 4)
assert(ns.Database:Get("width") == 300)
assert(ns.Database:Get("height") == 240)
assert(ns.Database:Get("opacity") == 1)
assert(BetterLootRollsDB.settings.welcomeShown == nil)

print("test_database.lua: ok")
