local function LoadApi(projectID, classicID, tbcID)
    local ns = {}

    WOW_PROJECT_ID = projectID
    WOW_PROJECT_CLASSIC = classicID
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = tbcID
    C_LootHistory = {
        GetNumItems = function() return 0 end,
        GetItem = function() end,
        GetPlayerInfo = function() end,
    }

    assert(loadfile("ApiCompat.lua"))("BetterLootRolls", ns)
    return ns.ApiCompat
end

assert(LoadApi(1, 1, 2):IsSupported() == true)
assert(LoadApi(2, 1, 2):IsSupported() == true)
assert(LoadApi(3, 1, 2):IsSupported() == false)

local compat = LoadApi(1, 1, 2)
assert(compat:GetChoiceTexture("NEED") == "Interface\\Buttons\\UI-GroupLoot-Dice-Up")
assert(compat:GetChoiceTexture("GREED") == "Interface\\Buttons\\UI-GroupLoot-Coin-Up")
assert(compat:GetChoiceTexture("DISENCHANT") == "Interface\\Buttons\\UI-GroupLoot-DE-Up")
assert(compat:GetChoiceTexture("PASS") == "Interface\\Buttons\\UI-GroupLoot-Pass-Up")
assert(compat:GetChoiceTexture("WAITING") == nil)

WOW_PROJECT_ID = 1
C_LootHistory.GetPlayerInfo = nil
local ns = {}
assert(loadfile("ApiCompat.lua"))("BetterLootRolls", ns)
assert(ns.ApiCompat:IsSupported() == false)

print("test_client_compat.lua: ok")
