local ns = {}
WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_CAMELOT = 18
WOW_PROJECT_ID = 18
Enum = { EncounterLootDropRollState = {
    NeedMainSpec = 0, NeedOffSpec = 1, Transmog = 2,
    Greed = 3, NoRoll = 4, Pass = 5,
} }
GetServerTime = function() return 123456 end
UnitFullName = function() return "Mage", "Realm" end
GetNormalizedRealmName = function() return "Realm" end
GetBuildInfo = function() return "1.60.1", "beta", "", 16001 end

local encounters = {
    { encounterID = 20, startTime = 100 },
    { encounterID = 10, startTime = 200 },
}
local oldDrop = {
    lootListKey = 1, startTime = 110, itemHyperlink = "item:1",
    rollInfos = {
        { playerName = "Mage", playerGUID = "Player-1", playerClass = "MAGE",
          state = 0, roll = 80, isSelf = true, isWinner = true },
        { playerName = "Rogue", playerGUID = "Player-2", playerClass = "ROGUE",
          state = 1, roll = 99 },
    },
}
oldDrop.winner = oldDrop.rollInfos[1]
local activeDrop = {
    lootListKey = 1, startTime = 210, itemHyperlink = "item:2",
    rollInfos = {
        { playerName = "Mage", playerGUID = "Player-1", playerClass = "MAGE",
          state = 4, isSelf = true },
        { playerName = "Rogue", playerGUID = "Player-2", playerClass = "ROGUE",
          state = 2 },
    },
}
local drops = { [20] = { oldDrop }, [10] = { activeDrop } }
C_LootHistory = {
    GetAllEncounterInfos = function() return encounters end,
    GetSortedDropsForEncounter = function(id) return drops[id] end,
}

for _, file in ipairs({ "Locales/enUS.lua", "Defaults.lua", "ApiCompat.lua",
    "Database.lua", "RollTracker.lua", "MainWindow.lua" }) do
    assert(loadfile(file))("BetterLootRolls", ns)
end
assert(ns.ApiCompat:IsSupported())
assert(ns.ApiCompat:GetClientReport():find("backend=encounter", 1, true))
local expected = { "NEED", "NEED_OFFSPEC", "TRANSMOG", "GREED", "WAITING", "PASS" }
for state = 0, 5 do
    assert(ns.ApiCompat:GetForeverChoice(state) == expected[state + 1])
end
assert(ns.ApiCompat:GetForeverChoice(99) == "UNKNOWN")
assert(ns.ApiCompat:GetChoice(0) ~= "NEED") -- Never treat the Forever enum as Classic.

ns.Database:Initialize(ns.ApiCompat:GetPlayerKey())
ns.RollTracker:Refresh()
local history = ns.Database:GetHistory()
assert(#history == 1 and #ns.RollTracker.active == 1)
local active = ns.RollTracker.active[1]
assert(active.players[1].choice == "WAITING" and active.players[1].isMe)
assert(active.players[2].choice == "TRANSMOG")
assert(history[1].players[2].choice == "NEED_OFFSPEC")
assert(active.rollID ~= history[1].rollID)
assert(ns.MainWindow:GetOwnChoice(active) == "WAITING")

activeDrop.rollInfos[1].state = 3
activeDrop.rollInfos[1].roll = 50
activeDrop.rollInfos[1].isWinner = true
activeDrop.winner = activeDrop.rollInfos[1]
ns.RollTracker:Refresh()
assert(#ns.RollTracker.active == 0 and #history == 2)
assert(history[1].itemLink == "item:2")
assert(history[1].players[1].choice == "GREED")
assert(history[1].players[1].isWinner and history[1].players[1].roll == 50)
assert(ns.MainWindow:GetRecordSummary(history[1]) == "Mage 50")

-- API sorting/encounter order may change without changing the completed roll.
activeDrop.rollInfos = { activeDrop.rollInfos[2], activeDrop.rollInfos[1] }
encounters = { encounters[2], encounters[1] }
ns.RollTracker:Refresh()
assert(#history == 2)

local passedDrop = {
    lootListKey = 2, startTime = 220, itemHyperlink = "item:3", allPassed = true,
    rollInfos = { { playerName = "Mage", playerClass = "MAGE", state = 4, isSelf = true } },
}
drops[10][2] = passedDrop
ns.RollTracker:Refresh()
assert(#history == 3 and history[1].allPassed)
assert(ns.MainWindow:GetRecordSummary(history[1]) == ns.L.ALL_PASSED)

-- Missing encounter data is transient; saved history survives Blizzard clearing.
drops[20] = nil
ns.RollTracker:Refresh()
assert(#history == 3)
encounters = {}
ns.RollTracker:Refresh()
assert(#history == 3 and #ns.RollTracker.active == 0)

-- Client-specific registration must never register the removed Classic events.
local frame
CreateFrame = function()
    frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript() end
    return frame
end
local shown, refreshed = 0, 0
ns.MainWindow = {
    Initialize = function() end,
    Refresh = function() refreshed = refreshed + 1 end,
    Show = function() shown = shown + 1 end,
}
ns.Options = { Initialize = function() end }
ns.SlashCommands = { Initialize = function() end }
assert(loadfile("Core.lua"))("BetterLootRolls", ns)
ns.Core:Initialize()
assert(frame.events.LOOT_HISTORY_UPDATE_DROP)
assert(frame.events.LOOT_HISTORY_UPDATE_ENCOUNTER)
assert(frame.events.LOOT_HISTORY_CLEAR_HISTORY)
assert(frame.events.LOOT_HISTORY_ONE_HUNDRED_ROLL)
assert(frame.events.LOOT_HISTORY_GO_TO_ENCOUNTER)
assert(not frame.events.LOOT_HISTORY_FULL_UPDATE)
assert(not frame.events.LOOT_HISTORY_AUTO_SHOW)
ns.Core:OnEvent("LOOT_HISTORY_GO_TO_ENCOUNTER", 10)
assert(shown == 1)
ns.Database:Set("autoShow", false)
ns.Core:OnEvent("LOOT_HISTORY_GO_TO_ENCOUNTER", 10)
ns.Core:OnEvent("LOOT_HISTORY_UPDATE_DROP", 10, 1)
ns.Core:OnEvent("LOOT_HISTORY_CLEAR_HISTORY")
assert(shown == 1 and refreshed == 4)
assert(#ns.Database:GetHistory() == 3)

-- Retail remains unsupported even though it has the same modern API.
WOW_PROJECT_ID = 1
assert(not ns.ApiCompat:IsSupported())
WOW_PROJECT_ID = 18
C_LootHistory.GetSortedDropsForEncounter = nil
assert(not ns.ApiCompat:IsSupported())
print("test_forever.lua: ok")
