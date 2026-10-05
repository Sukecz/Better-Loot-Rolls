local _, ns = ...

local ApiCompat = {}
ns.ApiCompat = ApiCompat

function ApiCompat:GetPlayerKey()
    local name, realm
    if type(UnitFullName) == "function" then
        name, realm = UnitFullName("player")
    end
    if (not name or name == "") and type(UnitName) == "function" then
        name = UnitName("player")
    end
    if type(GetNormalizedRealmName) == "function" then
        realm = GetNormalizedRealmName() or realm
    elseif (not realm or realm == "") and type(GetRealmName) == "function" then
        realm = GetRealmName()
    end

    if not name or name == "" then
        return nil
    end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

function ApiCompat:IsForever()
    return WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
end

function ApiCompat:IsSupported()
    if self:IsForever() then
        return type(C_LootHistory) == "table"
            and type(C_LootHistory.GetAllEncounterInfos) == "function"
            and type(C_LootHistory.GetSortedDropsForEncounter) == "function"
            and type(Enum) == "table"
            and type(Enum.EncounterLootDropRollState) == "table"
    end
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

function ApiCompat:GetLootEvents()
    if self:IsForever() then
        return {
            "LOOT_HISTORY_CLEAR_HISTORY",
            "LOOT_HISTORY_GO_TO_ENCOUNTER",
            "LOOT_HISTORY_UPDATE_DROP",
            "LOOT_HISTORY_UPDATE_ENCOUNTER",
            "LOOT_HISTORY_ONE_HUNDRED_ROLL",
        }
    end
    return {
        "LOOT_HISTORY_FULL_UPDATE",
        "LOOT_HISTORY_ROLL_CHANGED",
        "LOOT_HISTORY_ROLL_COMPLETE",
        "LOOT_HISTORY_AUTO_SHOW",
    }
end

function ApiCompat:IsAutoShowEvent(event)
    return event == (self:IsForever() and "LOOT_HISTORY_GO_TO_ENCOUNTER"
        or "LOOT_HISTORY_AUTO_SHOW")
end

function ApiCompat:GetForeverChoice(state)
    local states = Enum.EncounterLootDropRollState
    if state == states.NeedMainSpec then
        return "NEED"
    elseif state == states.NeedOffSpec then
        return "NEED_OFFSPEC"
    elseif state == states.Transmog then
        return "TRANSMOG"
    elseif state == states.Greed then
        return "GREED"
    elseif state == states.Pass then
        return "PASS"
    elseif state == nil or state == states.NoRoll then
        return "WAITING"
    end
    return "UNKNOWN"
end

function ApiCompat:GetNumItems()
    if self:IsForever() then
        -- One event-driven snapshot keeps item and player indices consistent.
        self.foreverItems = {}
        for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
            for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounter.encounterID) or {}) do
                local players = {}
                for _, roll in ipairs(drop.rollInfos or {}) do
                    players[#players + 1] = {
                        name = roll.playerName,
                        class = roll.playerClass,
                        rollType = self:GetForeverChoice(roll.state),
                        roll = roll.roll,
                        isWinner = not not roll.isWinner,
                        isMe = not not roll.isSelf,
                    }
                    if drop.winner and roll.playerGUID
                        and roll.playerGUID == drop.winner.playerGUID then
                        players[#players].isWinner = true
                    end
                end
                -- API roll order changes as results arrive. Stable player order
                -- prevents duplicate fingerprints after a reload or refresh.
                table.sort(players, function(left, right)
                    return (left.name or "") < (right.name or "")
                end)
                self.foreverItems[#self.foreverItems + 1] = {
                    rollID = table.concat({
                        tostring(encounter.encounterID), tostring(drop.lootListKey),
                        tostring(drop.startTime or encounter.startTime or 0),
                    }, ":"),
                    sortTime = drop.startTime or encounter.startTime or 0,
                    itemLink = drop.itemHyperlink,
                    numPlayers = #players,
                    isDone = drop.winner ~= nil or drop.allPassed == true,
                    allPassed = drop.allPassed == true,
                    players = players,
                }
            end
        end
        return #self.foreverItems
    end
    return C_LootHistory.GetNumItems() or 0
end

function ApiCompat:GetItem(index)
    if self:IsForever() then
        return self.foreverItems and self.foreverItems[index]
    end
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
    if self:IsForever() then
        local source = self.foreverItems[index].players[playerIndex]
        local player = {}
        for key, value in pairs(source) do
            player[key] = value
        end
        return player
    end
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
    if type(rollType) == "string" then
        local choices = {
            NEED = true, NEED_OFFSPEC = true, TRANSMOG = true, GREED = true,
            PASS = true, WAITING = true, UNKNOWN = true,
        }
        return choices[rollType] and rollType or "UNKNOWN"
    end
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
    if choice == "NEED" or choice == "NEED_OFFSPEC" then
        return "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
    elseif choice == "GREED" then
        return "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
    elseif choice == "DISENCHANT" then
        return "Interface\\Buttons\\UI-GroupLoot-DE-Up"
    elseif choice == "PASS" then
        return "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
    elseif choice == "TRANSMOG" then
        return "Interface\\Icons\\INV_Misc_ArmorKit_17"
    end

    return nil
end

function ApiCompat:RequestItemData(itemLink)
    if not C_Item or type(C_Item.RequestLoadItemDataByID) ~= "function" then
        return
    end

    local itemID
    if type(C_Item.GetItemInfoInstant) == "function" then
        itemID = C_Item.GetItemInfoInstant(itemLink)
    elseif type(GetItemInfoInstant) == "function" then
        itemID = GetItemInfoInstant(itemLink)
    end
    if not itemID and type(itemLink) == "string" then
        itemID = tonumber(itemLink:match("item:(%d+)"))
    end
    if itemID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
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

    self:RequestItemData(itemLink)
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function ApiCompat:GetClientReport()
    local version, build, buildDate, interfaceVersion = GetBuildInfo()
    return string.format(
        "version=%s build=%s date=%s interface=%s project=%s lootHistory=%s backend=%s",
        tostring(version),
        tostring(build),
        tostring(buildDate),
        tostring(interfaceVersion),
        tostring(WOW_PROJECT_ID),
        tostring(self:IsSupported()),
        self:IsForever() and "encounter" or "classic"
    )
end
