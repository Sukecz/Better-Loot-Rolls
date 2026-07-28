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

WOW_PROJECT_ID = 1
C_LootHistory.GetPlayerInfo = nil
local ns = {}
assert(loadfile("ApiCompat.lua"))("BetterLootRolls", ns)
assert(ns.ApiCompat:IsSupported() == false)

print("test_client_compat.lua: ok")
