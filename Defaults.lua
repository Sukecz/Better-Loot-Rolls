local _, ns = ...

ns.Constants = {
    MIN_HISTORY = 5,
    MAX_HISTORY = 100,
    MIN_WIDTH = 140,
    MAX_WIDTH = 900,
    HIDE_ITEM_NAME_WIDTH = 180,
    MIN_HEIGHT = 130,
    MAX_HEIGHT = 800,
}

ns.Defaults = {
    schemaVersion = 4,
    settings = {
        historyLimit = 20,
        autoShow = true,
        scale = 1,
        opacity = 1,
        width = 300,
        height = 240,
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 260,
            y = 0,
        },
    },
    history = {},
}
