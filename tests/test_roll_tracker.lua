local ns = {}

LOOT_ROLL_TYPE_PASS = 0
LOOT_ROLL_TYPE_NEED = 1
LOOT_ROLL_TYPE_GREED = 2
LOOT_ROLL_TYPE_DISENCHANT = 3

local items = {
    {
        rollID = 11,
        itemLink = "|Hitem:1|h[Test One]|h",
        numPlayers = 2,
        isDone = false,
        players = {
            { name = "Mage", class = "MAGE", rollType = 1 },
            { name = "Rogue", class = "ROGUE", rollType = 2 },
        },
    },
    {
        rollID = 10,
        itemLink = "|Hitem:2|h[Test Two]|h",
        numPlayers = 2,
        isDone = true,
        players = {
            { name = "Mage", class = "MAGE", rollType = 1, roll = 42 },
            { name = "Rogue", class = "ROGUE", rollType = 1, roll = 88, isWinner = true },
        },
    },
}

ns.ApiCompat = {
    GetNumItems = function()
        return #items
    end,
    GetItem = function(_, index)
        return items[index]
    end,
    GetPlayer = function(_, index, playerIndex)
        local source = items[index].players[playerIndex]
        local result = {}
        for key, value in pairs(source) do
            result[key] = value
        end
        return result
    end,
    GetChoice = function(_, rollType)
        return ({ [0] = "PASS", [1] = "NEED", [2] = "GREED", [3] = "DISENCHANT" })[rollType]
    end,
}

local history = {}
ns.Database = {
    AddCompleted = function(_, record)
        history[#history + 1] = record
        return true
    end,
    GetHistory = function()
        return history
    end,
}

GetServerTime = function()
    return 123456
end

assert(loadfile("RollTracker.lua"))("BetterLootRolls", ns)

local changed = 0
ns.RollTracker:SetChangedCallback(function()
    changed = changed + 1
end)
ns.RollTracker:Refresh()

assert(#ns.RollTracker.active == 1)
assert(ns.RollTracker.active[1].rollID == 11)
assert(ns.RollTracker.active[1].players[1].choice == "NEED")
assert(#history == 1)
assert(history[1].players[2].isWinner == true)
assert(history[1].completedAt == 123456)
assert(changed == 1)

ns.RollTracker:Refresh()
assert(#history == 1)

local display = ns.RollTracker:GetDisplayRecords()
assert(#display == 2)
assert(display[1].rollID == 11)
assert(display[2].rollID == 10)

print("test_roll_tracker.lua: ok")
