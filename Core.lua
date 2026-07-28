local addonName, ns = ...

ns.name = addonName

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        print("|cff33ff99Better Loot Rolls|r loaded. Type /blr after the full implementation is installed.")
    end
end)
