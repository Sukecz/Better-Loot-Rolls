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

local sourceFile = assert(io.open("MainWindow.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
assert(source:find('frame:SetFrameStrata%("MEDIUM"%)'))
assert(not source:find('frame:SetFrameStrata%("DIALOG"%)'))

ns.Constants = {
    HIDE_ITEM_NAME_WIDTH = 180,
}

assert(ns.MainWindow:ShouldHideItemName(140) == true)
assert(ns.MainWindow:ShouldHideItemName(179) == true)
assert(ns.MainWindow:ShouldHideItemName(180) == false)

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
assert(ns.MainWindow:GetRecordSummary(completed) == "|Ttexture:NEED:12:12|t Mage 88")
assert(ns.MainWindow:GetOwnChoice(completed) == "NEED")

local allPassed = {
    isDone = true,
    players = {
        { name = "Mage", choice = "PASS" },
        { name = "Rogue", choice = "PASS" },
    },
}
assert(ns.MainWindow:GetRecordSummary(allPassed) == "Everyone passed")

-- Hover and expanded views share a choice/roll ordering without changing history.
ns.L.NEED = "Need"
ns.L.GREED = "Greed"
ns.L.PASS = "Pass"
ns.L.YOUR_CHOICE = "Your roll: %s"
ns.L.YOU = "(You)"
local preview = {
    itemLink = "item:123",
    players = {
        { name = "Alpha-Realm", choice = "GREED", roll = 100, isMe = true },
        { name = "Zed-Realm", choice = "NEED", roll = 20 },
        { name = "Beta-Realm", choice = "NEED", roll = 90, isWinner = true },
        { name = "Aaron", choice = "PASS" },
        { name = "Ada", choice = "NEED", roll = 20 },
    },
}
local sorted = ns.MainWindow:GetSortedPlayers(preview)
assert(sorted[1].name == "Beta-Realm")
assert(sorted[2].name == "Ada" and sorted[3].name == "Zed-Realm")
assert(sorted[4].choice == "GREED" and sorted[5].choice == "PASS")
assert(preview.players[1].name == "Alpha-Realm")
local lines, title, owner, shown = {}, nil, nil, false
GameTooltip = {
    SetOwner = function(_, value) owner = value end,
    SetText = function(_, value) title = value end,
    AddLine = function(_, text) lines[#lines + 1] = { text } end,
    AddDoubleLine = function(_, left, right) lines[#lines + 1] = { left, right } end,
    Show = function() shown = true end,
}
local card = { record = preview }
ns.MainWindow:ShowRollTooltip(card)
assert(owner == card and title == "item:123" and shown)
assert(lines[1][1]:find("Beta", 1, true) and lines[1][1]:find("ReadyCheck-Ready", 1, true))
assert(lines[1][2] == "Need  90")
assert(lines[4][1] == "Alpha (You)" and lines[4][2] == "Greed  100")
card.ownChoiceButton = {}
ns.MainWindow:ShowOwnChoiceTooltip(card)
assert(owner == card.ownChoiceButton and title == "Your roll: Greed")
preview.players[2].roll = 90
sorted = ns.MainWindow:GetSortedPlayers(preview)
assert(sorted[1].isWinner and sorted[2].name == "Zed-Realm")
-- Large groups are not truncated and pending players have no invented roll.
preview.players = {}
for index = 1, 40 do
    preview.players[index] = { name = "Player" .. index, choice = "WAITING" }
end
lines = {}
ns.MainWindow:ShowRollTooltip(card)
assert(#lines == 40 and lines[1][2] == "Waiting")
preview.players = {}
preview.isDone = true
lines = {}
ns.MainWindow:ShowRollTooltip(card)
assert(#lines == 1 and lines[1][1] == "Everyone passed")

local visibilitySetting
local frameShown = false
ns.Database = {
    Set = function(_, key, value)
        assert(key == "windowShown")
        visibilitySetting = value
    end,
}
ns.MainWindow.frame = {
    Show = function()
        frameShown = true
    end,
    Hide = function()
        frameShown = false
    end,
    IsShown = function()
        return frameShown
    end,
}
ns.MainWindow:Show()
assert(visibilitySetting == true)
assert(ns.MainWindow:IsShown() == true)
ns.MainWindow:Hide()
assert(visibilitySetting == false)
assert(ns.MainWindow:IsShown() == false)

print("test_main_window.lua: ok")
