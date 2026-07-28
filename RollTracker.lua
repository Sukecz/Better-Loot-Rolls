local _, ns = ...

local RollTracker = {
    active = {},
    captured = {},
}
ns.RollTracker = RollTracker

local function BuildFingerprint(record)
    local parts = {
        tostring(record.rollID),
        tostring(record.itemLink),
    }

    for _, player in ipairs(record.players) do
        parts[#parts + 1] = table.concat({
            tostring(player.name),
            tostring(player.rollType),
            tostring(player.roll),
            tostring(player.isWinner),
        }, ":")
    end

    return table.concat(parts, "|")
end

function RollTracker:SetChangedCallback(callback)
    self.changedCallback = callback
end

function RollTracker:BuildRecord(historyIndex)
    local item = ns.ApiCompat:GetItem(historyIndex)
    if not item then
        return nil
    end

    local record = {
        rollID = item.rollID,
        itemLink = item.itemLink,
        isDone = item.isDone,
        isMasterLoot = item.isMasterLoot,
        isCurrency = item.isCurrency,
        players = {},
    }

    for playerIndex = 1, item.numPlayers do
        local player = ns.ApiCompat:GetPlayer(historyIndex, playerIndex)
        player.choice = ns.ApiCompat:GetChoice(player.rollType)
        record.players[#record.players + 1] = player
    end

    if record.isDone then
        record.completedAt = type(GetServerTime) == "function" and GetServerTime() or time()
        record.fingerprint = BuildFingerprint(record)
    end

    return record
end

function RollTracker:Refresh()
    local active = {}
    local completed = {}
    local completedChanged = false

    for historyIndex = 1, ns.ApiCompat:GetNumItems() do
        local record = self:BuildRecord(historyIndex)
        if record then
            if record.isDone and record.itemLink then
                completed[#completed + 1] = record
            else
                -- A completed item can briefly have no link while its item data
                -- is being fetched. Keep it visible but do not persist an
                -- incomplete duplicate; LOOT_HISTORY_FULL_UPDATE will retry it.
                active[#active + 1] = record
            end
        end
    end

    table.sort(active, function(left, right)
        return left.rollID > right.rollID
    end)
    table.sort(completed, function(left, right)
        return left.rollID < right.rollID
    end)

    for _, record in ipairs(completed) do
        if not self.captured[record.fingerprint] then
            self.captured[record.fingerprint] = true
            if ns.Database:AddCompleted(record) then
                completedChanged = true
            end
        end
    end

    self.active = active

    if self.changedCallback then
        self.changedCallback(completedChanged)
    end
end

function RollTracker:GetDisplayRecords()
    local records = {}

    for _, record in ipairs(self.active) do
        records[#records + 1] = record
    end
    for _, record in ipairs(ns.Database:GetHistory()) do
        records[#records + 1] = record
    end

    return records
end
