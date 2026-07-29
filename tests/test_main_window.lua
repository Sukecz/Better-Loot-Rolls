local ns = {
    L = {
        ALL_PASSED = "Everyone passed",
        COMPLETE = "Complete",
        ROLL_PROGRESS = "%d/%d",
        UNKNOWN = "Unknown",
        WAITING = "Waiting",
    },
    ApiCompat = {
        GetChoiceTexture = function(_, choice)
            return choice and ("texture:" .. choice) or nil
        end,
    },
}

RAID_CLASS_COLORS = {
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
}

assert(loadfile("MainWindow.lua"))("BetterLootRolls", ns)

local active = {
    rollID = 12,
    itemLink = "|Hitem:1|h[Test]|h",
    isDone = false,
    players = {
        { name = "Mage", choice = "NEED" },
        { name = "Rogue", choice = "WAITING" },
    },
}
local summary = ns.MainWindow:GetRecordSummary(active)
assert(summary == "1/2")
assert(ns.MainWindow:GetOwnChoice(active) == nil)

ns.MainWindow.expandedRecords[ns.MainWindow:GetRecordKey(active)] = true

local completed = {
    rollID = 12,
    itemLink = "|Hitem:1|h[Test]|h",
    fingerprint = "completed-roll",
    isDone = true,
    players = {
        {
            name = "Mage-Realm",
            class = "MAGE",
            choice = "NEED",
            roll = 88,
            isWinner = true,
            isMe = true,
        },
        { name = "Rogue", choice = "GREED", roll = 42 },
    },
}
ns.MainWindow:PreserveExpandedState({ completed })
assert(ns.MainWindow.expandedRecords[ns.MainWindow:GetRecordKey(completed)] == true)
assert(ns.MainWindow:GetRecordSummary(completed) == "Mage 88")
assert(ns.MainWindow:GetOwnChoice(completed) == "NEED")

local allPassed = {
    isDone = true,
    players = {
        { name = "Mage", choice = "PASS" },
        { name = "Rogue", choice = "PASS" },
    },
}
assert(ns.MainWindow:GetRecordSummary(allPassed) == "Everyone passed")

print("test_main_window.lua: ok")
