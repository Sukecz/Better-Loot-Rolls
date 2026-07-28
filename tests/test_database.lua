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
assert(ns.Database:Get("width") == 340)
assert(ns.Database:Get("height") == 800)
assert(ns.Database:Get("autoShow") == false)
assert(#ns.Database:GetHistory() == 100)

ns.Database:Set("historyLimit", 5)
assert(#ns.Database:GetHistory() == 5)

local record = { fingerprint = "unique" }
assert(ns.Database:AddCompleted(record) == true)
assert(ns.Database:AddCompleted(record) == false)

print("test_database.lua: ok")
