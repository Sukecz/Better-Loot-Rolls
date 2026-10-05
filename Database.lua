local _, ns = ...

local Database = {}
ns.Database = Database

local LEGACY_HISTORY_KEY = "__legacyAccountWide"

local function Clamp(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then
        return fallback
    end

    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end

    return value
end

local function CopyTable(source)
    local result = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = CopyTable(value)
        else
            result[key] = value
        end
    end
    return result
end

local function MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = type(value) == "table" and CopyTable(value) or value
        elseif type(value) == "table" and type(target[key]) == "table" then
            MergeDefaults(target[key], value)
        end
    end
end

local function Migrate(data)
    local schemaVersion = tonumber(data.schemaVersion)
    if schemaVersion and schemaVersion < 2 and type(data.settings) == "table" then
        -- Preserve custom geometry. Only replace the original alpha defaults
        -- with the new compact defaults.
        if data.settings.width == 460 then
            data.settings.width = ns.Defaults.settings.width
        end
        if data.settings.height == 360 then
            data.settings.height = ns.Defaults.settings.height
        end
    end
    if schemaVersion and schemaVersion < 3 and type(data.settings) == "table" then
        if data.settings.width == 360 then
            data.settings.width = ns.Defaults.settings.width
        end
        if data.settings.height == 260 then
            data.settings.height = ns.Defaults.settings.height
        end
    end
    if (not schemaVersion or schemaVersion < 4) and type(data.settings) == "table" then
        data.settings.welcomeShown = nil
    end
    if not schemaVersion or schemaVersion < 5 then
        if type(data.histories) ~= "table" then
            data.histories = {}
        end
        if type(data.history) == "table" and #data.history > 0 then
            data.histories[LEGACY_HISTORY_KEY] = data.history
        end
        data.history = nil
    end
end

function Database:Initialize(characterKey)
    if type(BetterLootRollsDB) ~= "table" then
        BetterLootRollsDB = {}
    end

    Migrate(BetterLootRollsDB)
    MergeDefaults(BetterLootRollsDB, ns.Defaults)
    BetterLootRollsDB.schemaVersion = ns.Defaults.schemaVersion
    self.data = BetterLootRollsDB
    self:Validate()
    self:SetCharacterKey(characterKey)
end

function Database:Validate()
    local constants = ns.Constants
    local defaults = ns.Defaults.settings
    local settings = self.data.settings

    settings.historyLimit = math.floor(Clamp(
        settings.historyLimit,
        constants.MIN_HISTORY,
        constants.MAX_HISTORY,
        defaults.historyLimit
    ))
    settings.scale = Clamp(settings.scale, 0.75, 1.5, defaults.scale)
    settings.opacity = Clamp(settings.opacity, 0.2, 1, defaults.opacity)
    settings.width = Clamp(
        settings.width,
        constants.MIN_WIDTH,
        constants.MAX_WIDTH,
        defaults.width
    )
    settings.height = Clamp(
        settings.height,
        constants.MIN_HEIGHT,
        constants.MAX_HEIGHT,
        defaults.height
    )
    settings.autoShow = settings.autoShow ~= false
    settings.windowShown = settings.windowShown == true

    if type(settings.position) ~= "table" then
        settings.position = CopyTable(defaults.position)
    end
    settings.position.point = type(settings.position.point) == "string"
        and settings.position.point or defaults.position.point
    settings.position.relativePoint = type(settings.position.relativePoint) == "string"
        and settings.position.relativePoint or defaults.position.relativePoint
    settings.position.x = tonumber(settings.position.x) or defaults.position.x
    settings.position.y = tonumber(settings.position.y) or defaults.position.y

    if type(self.data.histories) ~= "table" then
        self.data.histories = {}
    end
    for characterKey, history in pairs(self.data.histories) do
        if type(characterKey) ~= "string" or type(history) ~= "table" then
            self.data.histories[characterKey] = nil
        else
            self:PruneHistory(history)
        end
    end
end

function Database:Get(key)
    return self.data.settings[key]
end

function Database:Set(key, value)
    self.data.settings[key] = value
    self:Validate()
end

function Database:SetCharacterKey(characterKey)
    if type(characterKey) ~= "string" or characterKey == "" then
        self.characterKey = nil
        return false
    end

    self.characterKey = characterKey
    if type(self.data.histories[characterKey]) ~= "table" then
        self.data.histories[characterKey] = {}
    end
    self:PruneHistory(self.data.histories[characterKey])
    return true
end

function Database:GetHistory()
    if not self.characterKey then
        self.emptyHistory = self.emptyHistory or {}
        return self.emptyHistory
    end
    return self.data.histories[self.characterKey]
end

function Database:PruneHistory(history)
    history = history or self:GetHistory()
    local limit = self.data.settings.historyLimit
    while #history > limit do
        table.remove(history)
    end
end

function Database:AddCompleted(record)
    if not self.characterKey then
        return false
    end

    local history = self:GetHistory()
    if record.fingerprint then
        -- The whole list is bounded to 100. A client can return more than five
        -- completed drops on login; check them all before importing duplicates.
        for index = 1, #history do
            if history[index].fingerprint == record.fingerprint then
                return false
            end
        end
    end

    table.insert(history, 1, record)
    self:PruneHistory(history)
    return true
end

function Database:ClearHistory()
    if self.characterKey then
        self.data.histories[self.characterKey] = {}
    end
end

function Database:ResetWindow()
    local defaults = ns.Defaults.settings
    self.data.settings.width = defaults.width
    self.data.settings.height = defaults.height
    self.data.settings.scale = defaults.scale
    self.data.settings.opacity = defaults.opacity
    self.data.settings.position = CopyTable(defaults.position)
end
