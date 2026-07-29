local _, ns = ...

local ApiCompat = {}
ns.ApiCompat = ApiCompat

function ApiCompat:IsSupported()
    local isClassicEra = WOW_PROJECT_CLASSIC
        and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
    local isTBCClassic = WOW_PROJECT_BURNING_CRUSADE_CLASSIC
        and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

    return (isClassicEra or isTBCClassic)
        and type(C_LootHistory) == "table"
        and type(C_LootHistory.GetNumItems) == "function"
        and type(C_LootHistory.GetItem) == "function"
        and type(C_LootHistory.GetPlayerInfo) == "function"
end

function ApiCompat:GetNumItems()
    return C_LootHistory.GetNumItems() or 0
end

function ApiCompat:GetItem(index)
    local rollID, itemLink, numPlayers, isDone, winnerIndex, isMasterLoot, isCurrency =
        C_LootHistory.GetItem(index)

    if not rollID then
        return nil
    end

    return {
        rollID = rollID,
        itemLink = itemLink,
        numPlayers = numPlayers or 0,
        isDone = not not isDone,
        winnerIndex = winnerIndex,
        isMasterLoot = not not isMasterLoot,
        isCurrency = not not isCurrency,
    }
end

function ApiCompat:GetPlayer(index, playerIndex)
    local name, class, rollType, roll, isWinner, isMe =
        C_LootHistory.GetPlayerInfo(index, playerIndex)

    return {
        name = name,
        class = class,
        rollType = rollType,
        roll = roll,
        isWinner = not not isWinner,
        isMe = not not isMe,
    }
end

function ApiCompat:GetChoice(rollType)
    if rollType == nil then
        return "WAITING"
    elseif rollType == LOOT_ROLL_TYPE_NEED then
        return "NEED"
    elseif rollType == LOOT_ROLL_TYPE_GREED then
        return "GREED"
    elseif rollType == LOOT_ROLL_TYPE_DISENCHANT then
        return "DISENCHANT"
    elseif rollType == LOOT_ROLL_TYPE_PASS then
        return "PASS"
    end

    return "UNKNOWN"
end

function ApiCompat:GetChoiceTexture(choice)
    if choice == "NEED" then
        return "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
    elseif choice == "GREED" then
        return "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
    elseif choice == "DISENCHANT" then
        return "Interface\\Buttons\\UI-GroupLoot-DE-Up"
    elseif choice == "PASS" then
        return "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
    end

    return nil
end

function ApiCompat:GetItemTexture(itemLink)
    if not itemLink then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    if C_Item and type(C_Item.GetItemInfo) == "function" then
        local _, _, _, _, _, _, _, _, _, texture = C_Item.GetItemInfo(itemLink)
        if texture then
            return texture
        end
    end

    if type(GetItemInfo) == "function" then
        local texture = select(10, GetItemInfo(itemLink))
        if texture then
            return texture
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function ApiCompat:GetClientReport()
    local version, build, buildDate, interfaceVersion = GetBuildInfo()
    return string.format(
        "version=%s build=%s date=%s interface=%s project=%s lootHistory=%s",
        tostring(version),
        tostring(build),
        tostring(buildDate),
        tostring(interfaceVersion),
        tostring(WOW_PROJECT_ID),
        tostring(self:IsSupported())
    )
end
