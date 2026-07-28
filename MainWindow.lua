local _, ns = ...

local MainWindow = {
    cards = {},
}
ns.MainWindow = MainWindow

local function CreateBackdropFrame(frameType, name, parent)
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    return CreateFrame(frameType, name, parent, template)
end

local function SetBackdrop(frame, color)
    if not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(color[1], color[2], color[3], color[4])
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
end

local function GetClassColor(class)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then
        return color.r, color.g, color.b
    end
    return 0.85, 0.85, 0.85
end

local function GetChoiceColor(choice)
    if choice == "NEED" then
        return 0.25, 0.75, 1
    elseif choice == "GREED" then
        return 1, 0.82, 0
    elseif choice == "DISENCHANT" then
        return 0.72, 0.38, 1
    elseif choice == "PASS" then
        return 0.55, 0.55, 0.55
    end
    return 0.75, 0.75, 0.75
end

function MainWindow:CreatePlayerRow(card)
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(20)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()
    row.background:SetColorTexture(1, 1, 1, 0.035)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetJustifyH("LEFT")

    row.choice = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.choice:SetJustifyH("LEFT")

    row.roll = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.roll:SetJustifyH("RIGHT")

    return row
end

function MainWindow:CreateCard()
    local card = CreateBackdropFrame("Button", nil, self.scrollChild)
    SetBackdrop(card, { 0.035, 0.035, 0.035, 0.92 })
    card:RegisterForClicks("LeftButtonUp")

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(32, 32)
    card.icon:SetPoint("TOPLEFT", 8, -8)

    card.itemName = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.itemName:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 8, -1)
    card.itemName:SetJustifyH("LEFT")
    card.itemName:SetWordWrap(false)

    card.status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.status:SetPoint("TOPRIGHT", -8, -10)
    card.status:SetJustifyH("RIGHT")

    card.playerRows = {}

    card:SetScript("OnEnter", function(frame)
        if not frame.itemLink then
            return
        end
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(frame.itemLink)
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    card:SetScript("OnClick", function(frame)
        if frame.itemLink and IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(frame.itemLink)
        end
    end)

    return card
end

function MainWindow:RenderPlayerRow(row, player, rowIndex, cardWidth)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 8, -44 - ((rowIndex - 1) * 20))
    row:SetWidth(cardWidth - 16)

    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", 3, 0)
    row.name:SetWidth((cardWidth - 22) * 0.52)

    row.choice:ClearAllPoints()
    row.choice:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
    row.choice:SetWidth((cardWidth - 22) * 0.27)

    row.roll:ClearAllPoints()
    row.roll:SetPoint("RIGHT", -4, 0)
    row.roll:SetWidth((cardWidth - 22) * 0.16)

    local prefix = player.isWinner and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t " or ""
    row.name:SetText(prefix .. (player.name or ns.L.UNKNOWN))
    row.name:SetTextColor(GetClassColor(player.class))

    row.choice:SetText(ns.L[player.choice] or ns.L.UNKNOWN)
    row.choice:SetTextColor(GetChoiceColor(player.choice))

    if player.roll then
        row.roll:SetText(player.isWinner and "|cffffd100" .. player.roll .. "|r" or tostring(player.roll))
    else
        row.roll:SetText(player.choice == "WAITING" and "…" or "—")
    end

    row.background:SetShown(rowIndex % 2 == 0)
    row:Show()
end

function MainWindow:RenderCard(card, record, topOffset, cardWidth)
    local playerCount = math.max(1, #record.players)
    local cardHeight = 50 + (playerCount * 20)

    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", 0, -topOffset)
    card:SetSize(cardWidth, cardHeight)
    card.itemLink = record.itemLink
    card.icon:SetTexture(ns.ApiCompat:GetItemTexture(record.itemLink))
    card.itemName:SetText(record.itemLink or ns.L.UNKNOWN)
    card.itemName:SetWidth(math.max(80, cardWidth - 190))
    card.status:SetText(record.isDone and ns.L.COMPLETE or ns.L.ACTIVE)
    card.status:SetTextColor(record.isDone and 0.65 or 0.3, record.isDone and 0.65 or 1, 0.3)

    if #record.players == 0 then
        local row = card.playerRows[1] or self:CreatePlayerRow(card)
        card.playerRows[1] = row
        self:RenderPlayerRow(row, {
            name = record.isDone and ns.L.ALL_PASSED or ns.L.WAITING,
            choice = record.isDone and "PASS" or "WAITING",
        }, 1, cardWidth)
    else
        for playerIndex, player in ipairs(record.players) do
            local row = card.playerRows[playerIndex] or self:CreatePlayerRow(card)
            card.playerRows[playerIndex] = row
            self:RenderPlayerRow(row, player, playerIndex, cardWidth)
        end
    end

    for playerIndex = playerCount + 1, #card.playerRows do
        card.playerRows[playerIndex]:Hide()
    end

    card:Show()
    return cardHeight
end

function MainWindow:Refresh()
    if not self.frame then
        return
    end

    local records = ns.RollTracker:GetDisplayRecords()
    local cardWidth = math.max(280, self.frame:GetWidth() - 52)
    local offset = 0

    for index, record in ipairs(records) do
        local card = self.cards[index] or self:CreateCard()
        self.cards[index] = card
        offset = offset + self:RenderCard(card, record, offset, cardWidth) + 6
    end

    for index = #records + 1, #self.cards do
        self.cards[index]:Hide()
    end

    self.emptyText:SetShown(#records == 0)
    self.scrollChild:SetSize(cardWidth, math.max(1, offset))
end

function MainWindow:SaveGeometry()
    local frame = self.frame
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    ns.Database:Set("width", frame:GetWidth())
    ns.Database:Set("height", frame:GetHeight())
    ns.Database:Set("position", {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    })
end

function MainWindow:ApplySettings()
    local settings = ns.Database.data.settings
    local frame = self.frame

    frame:SetScale(settings.scale)
    frame:SetSize(settings.width, settings.height)
    frame:ClearAllPoints()
    frame:SetPoint(
        settings.position.point,
        UIParent,
        settings.position.relativePoint,
        settings.position.x,
        settings.position.y
    )
    self:Refresh()
end

function MainWindow:Initialize()
    if self.frame then
        return
    end

    local settings = ns.Database.data.settings
    local frame = CreateBackdropFrame("Frame", "BetterLootRollsFrame", UIParent)
    self.frame = frame
    SetBackdrop(frame, { 0.015, 0.015, 0.015, 0.96 })
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(
            ns.Constants.MIN_WIDTH,
            ns.Constants.MIN_HEIGHT,
            ns.Constants.MAX_WIDTH,
            ns.Constants.MAX_HEIGHT
        )
    else
        frame:SetMinResize(ns.Constants.MIN_WIDTH, ns.Constants.MIN_HEIGHT)
        frame:SetMaxResize(ns.Constants.MAX_WIDTH, ns.Constants.MAX_HEIGHT)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -13)
    title:SetText(ns.L.TITLE)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 2, 2)

    local optionsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    optionsButton:SetSize(74, 22)
    optionsButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", 2, -5)
    optionsButton:SetText(ns.L.OPTIONS)
    optionsButton:SetScript("OnClick", function()
        ns.Options:Show()
    end)

    local dragArea = CreateFrame("Frame", nil, frame)
    dragArea:SetPoint("TOPLEFT", 4, -4)
    dragArea:SetPoint("TOPRIGHT", optionsButton, "TOPLEFT", -4, 0)
    dragArea:SetHeight(34)
    dragArea:EnableMouse(true)
    dragArea:RegisterForDrag("LeftButton")
    dragArea:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragArea:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        self:SaveGeometry()
    end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.45, 0.45, 0.45, 0.5)
    divider:SetPoint("TOPLEFT", 9, -39)
    divider:SetPoint("TOPRIGHT", -9, -39)
    divider:SetHeight(1)

    local scrollFrame = CreateFrame(
        "ScrollFrame",
        "BetterLootRollsScrollFrame",
        frame,
        "UIPanelScrollFrameTemplate"
    )
    self.scrollFrame = scrollFrame
    scrollFrame:SetPoint("TOPLEFT", 10, -48)
    scrollFrame:SetPoint("BOTTOMRIGHT", -31, 14)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    self.scrollChild = scrollChild
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.emptyText = emptyText
    emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 10)
    emptyText:SetText(ns.L.NO_ROLLS)

    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(18, 18)
    resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        self:SaveGeometry()
        self:Refresh()
    end)

    frame:SetScript("OnSizeChanged", function()
        self:Refresh()
    end)
    frame:SetScript("OnShow", function()
        self:Refresh()
    end)

    self:ApplySettings()
    frame:Hide()
end

function MainWindow:Show()
    self.frame:Show()
end

function MainWindow:Hide()
    self.frame:Hide()
end

function MainWindow:IsShown()
    return self.frame and self.frame:IsShown()
end
