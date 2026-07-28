local _, ns = ...

local Database = {}
ns.Database = Database

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
end

function Database:Initialize()
    if type(BetterLootRollsDB) ~= "table" then
        BetterLootRollsDB = {}
    end

    Migrate(BetterLootRollsDB)
    MergeDefaults(BetterLootRollsDB, ns.Defaults)
    BetterLootRollsDB.schemaVersion = ns.Defaults.schemaVersion
    self.data = BetterLootRollsDB
    self:Validate()
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

    if type(settings.position) ~= "table" then
        settings.position = CopyTable(defaults.position)
    end
    settings.position.point = type(settings.position.point) == "string"
        and settings.position.point or defaults.position.point
    settings.position.relativePoint = type(settings.position.relativePoint) == "string"
        and settings.position.relativePoint or defaults.position.relativePoint
    settings.position.x = tonumber(settings.position.x) or defaults.position.x
    settings.position.y = tonumber(settings.position.y) or defaults.position.y

    if type(self.data.history) ~= "table" then
        self.data.history = {}
    end
    self:PruneHistory()
end

function Database:Get(key)
    return self.data.settings[key]
end

function Database:Set(key, value)
    self.data.settings[key] = value
    self:Validate()
end

function Database:GetHistory()
    return self.data.history
end

function Database:PruneHistory()
    local history = self.data.history
    local limit = self.data.settings.historyLimit
    while #history > limit do
        table.remove(history)
    end
end

function Database:AddCompleted(record)
    if record.fingerprint then
        for index = 1, math.min(5, #self.data.history) do
            if self.data.history[index].fingerprint == record.fingerprint then
                return false
            end
        end
    end

    table.insert(self.data.history, 1, record)
    self:PruneHistory()
    return true
end

function Database:ClearHistory()
    self.data.history = {}
end

function Database:ResetWindow()
    local defaults = ns.Defaults.settings
    self.data.settings.width = defaults.width
    self.data.settings.height = defaults.height
    self.data.settings.scale = defaults.scale
    self.data.settings.opacity = defaults.opacity
    self.data.settings.position = CopyTable(defaults.position)
end
