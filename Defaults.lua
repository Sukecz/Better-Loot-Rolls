local _, ns = ...

ns.Constants = {
    MIN_HISTORY = 5,
    MAX_HISTORY = 100,
    MIN_WIDTH = 340,
    MAX_WIDTH = 900,
    MIN_HEIGHT = 220,
    MAX_HEIGHT = 800,
}

ns.Defaults = {
    schemaVersion = 1,
    settings = {
        historyLimit = 20,
        autoShow = true,
        scale = 1,
        width = 460,
        height = 360,
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 260,
            y = 0,
        },
    },
    history = {},
}
