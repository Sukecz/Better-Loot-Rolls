local _, ns = ...

local MainWindow = {
    cards = {},
    expandedRecords = {},
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
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(color[1], color[2], color[3], color[4])
    frame:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
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

local function TruncateUtf8(text, maxCharacters)
    local byteIndex = 1
    local characterCount = 0
    local byteLength = #text

    while byteIndex <= byteLength and characterCount < maxCharacters do
        local firstByte = string.byte(text, byteIndex)
        local characterBytes = 1
        if firstByte >= 240 then
            characterBytes = 4
        elseif firstByte >= 224 then
            characterBytes = 3
        elseif firstByte >= 192 then
            characterBytes = 2
        end
        byteIndex = byteIndex + characterBytes
        characterCount = characterCount + 1
    end

    if byteIndex <= byteLength then
        return string.sub(text, 1, byteIndex - 1) .. "…"
    end
    return text
end

local function GetCompactPlayerName(name)
    if not name then
        return ns.L.UNKNOWN
    end

    local shortName = type(Ambiguate) == "function" and Ambiguate(name, "short")
        or string.match(name, "^([^-]+)")
        or name
    return TruncateUtf8(shortName, 9)
end

local function GetCompactChoice(choice)
    if choice == "DISENCHANT" then
        return "DE"
    elseif choice == "WAITING" then
        return "…"
    end
    return ns.L[choice] or ns.L.UNKNOWN
end

function MainWindow:CreatePlayerRow(card)
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(16)

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
    local card = CreateFrame("Button", nil, self.scrollChild)
    card:RegisterForClicks("LeftButtonUp")

    card.headerBackground = card:CreateTexture(nil, "BACKGROUND")
    card.headerBackground:SetPoint("TOPLEFT")
    card.headerBackground:SetPoint("TOPRIGHT")
    card.headerBackground:SetHeight(29)
    card.headerBackground:SetColorTexture(0.075, 0.09, 0.115, 0.72)

    card.separator = card:CreateTexture(nil, "BORDER")
    card.separator:SetPoint("BOTTOMLEFT")
    card.separator:SetPoint("BOTTOMRIGHT")
    card.separator:SetHeight(1)
    card.separator:SetColorTexture(0.18, 0.23, 0.3, 0.5)

    card.expandIndicator = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.expandIndicator:SetPoint("TOPLEFT", 4, -9)
    card.expandIndicator:SetWidth(9)
    card.expandIndicator:SetJustifyH("CENTER")
    card.expandIndicator:SetTextColor(0.65, 0.72, 0.82)

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(22, 22)
    card.icon:SetPoint("TOPLEFT", 16, -4)

    card.itemName = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.itemName:SetPoint("LEFT", card.icon, "RIGHT", 4, 0)
    card.itemName:SetJustifyH("LEFT")
    card.itemName:SetWordWrap(false)

    card.status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.status:SetPoint("TOPRIGHT", -4, -7)
    card.status:SetJustifyH("RIGHT")

    card.ownChoiceIcon = card:CreateTexture(nil, "ARTWORK")
    card.ownChoiceIcon:SetSize(18, 18)
    card.ownChoiceIcon:SetPoint("TOPRIGHT", -3, -6)

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
            return
        end

        if frame.recordKey then
            self.expandedRecords[frame.recordKey] = not self.expandedRecords[frame.recordKey]
            self:Refresh()
        end
    end)

    return card
end

function MainWindow:GetRecordKey(record)
    if record.fingerprint then
        return "completed:" .. record.fingerprint
    end
    return "active:" .. self:GetLifecycleKey(record)
end

function MainWindow:GetLifecycleKey(record)
    return table.concat({
        tostring(record.rollID or "unknown"),
        tostring(record.itemLink or "unknown"),
    }, ":")
end

function MainWindow:PreserveExpandedState(records)
    local activeLifecycleKeys = {}
    for _, record in ipairs(records) do
        if not record.fingerprint then
            activeLifecycleKeys[self:GetLifecycleKey(record)] = true
        end
    end

    for _, record in ipairs(records) do
        if record.fingerprint then
            local lifecycleKey = self:GetLifecycleKey(record)
            local activeKey = "active:" .. lifecycleKey
            if not activeLifecycleKeys[lifecycleKey] and self.expandedRecords[activeKey] then
                self.expandedRecords[self:GetRecordKey(record)] = true
                self.expandedRecords[activeKey] = nil
            end
        end
    end
end

function MainWindow:GetRecordSummary(record)
    if not record.isDone then
        local decided = 0
        for _, player in ipairs(record.players) do
            if player.choice and player.choice ~= "WAITING" then
                decided = decided + 1
            end
        end

        if #record.players == 0 then
            return ns.L.WAITING, 0.3, 1, 0.3
        end
        return string.format(ns.L.ROLL_PROGRESS, decided, #record.players), 0.3, 1, 0.3
    end

    for _, player in ipairs(record.players) do
        if player.isWinner then
            local summary = GetCompactPlayerName(player.name)
            if player.roll then
                summary = summary .. " " .. tostring(player.roll)
            end
            local red, green, blue = GetClassColor(player.class)
            return summary, red, green, blue
        end
    end

    local allPassed = #record.players > 0
    for _, player in ipairs(record.players) do
        if player.choice ~= "PASS" then
            allPassed = false
            break
        end
    end
    if allPassed or #record.players == 0 then
        return ns.L.ALL_PASSED, 0.55, 0.55, 0.55
    end

    return ns.L.COMPLETE, 0.65, 0.65, 0.65
end

function MainWindow:GetOwnChoice(record)
    for _, player in ipairs(record.players) do
        if player.isMe then
            return player.choice
        end
    end

    return nil
end

function MainWindow:RenderPlayerRow(row, player, rowIndex, cardWidth)
    local rowWidth = cardWidth - 8
    local choiceWidth = 48
    local rollWidth = 24
    local nameWidth = math.max(54, rowWidth - choiceWidth - rollWidth - 2)

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 4, -30 - ((rowIndex - 1) * 16))
    row:SetWidth(rowWidth)

    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", 1, 0)
    row.name:SetWidth(nameWidth)

    row.choice:ClearAllPoints()
    row.choice:SetPoint("LEFT", row.name, "RIGHT", 1, 0)
    row.choice:SetWidth(choiceWidth)

    row.roll:ClearAllPoints()
    row.roll:SetPoint("RIGHT", -1, 0)
    row.roll:SetWidth(rollWidth)

    local prefix = player.isWinner and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t " or ""
    row.name:SetText(prefix .. GetCompactPlayerName(player.name))
    row.name:SetTextColor(GetClassColor(player.class))

    row.choice:SetText(GetCompactChoice(player.choice))
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
    local recordKey = self:GetRecordKey(record)
    local isExpanded = self.expandedRecords[recordKey] == true
    local cardHeight = isExpanded and (33 + (playerCount * 16)) or 30

    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", 0, -topOffset)
    card:SetSize(cardWidth, cardHeight)
    card.recordKey = recordKey
    card.itemLink = record.itemLink
    card.expandIndicator:SetText(isExpanded and "-" or "+")
    card.icon:SetTexture(ns.ApiCompat:GetItemTexture(record.itemLink))
    card.itemName:SetText(record.itemLink or ns.L.UNKNOWN)
    local ownChoiceTexture = ns.ApiCompat:GetChoiceTexture(self:GetOwnChoice(record))
    card.ownChoiceIcon:SetTexture(ownChoiceTexture)
    card.ownChoiceIcon:SetShown(ownChoiceTexture ~= nil)
    card.itemName:SetWidth(math.max(48, cardWidth - (ownChoiceTexture and 153 or 135)))
    local statusText, statusRed, statusGreen, statusBlue = self:GetRecordSummary(record)
    card.status:ClearAllPoints()
    if ownChoiceTexture then
        card.status:SetPoint("RIGHT", card.ownChoiceIcon, "LEFT", -3, 0)
    else
        card.status:SetPoint("TOPRIGHT", -4, -7)
    end
    card.status:SetText(statusText)
    card.status:SetTextColor(statusRed, statusGreen, statusBlue)

    if not isExpanded then
        for playerIndex = 1, #card.playerRows do
            card.playerRows[playerIndex]:Hide()
        end
    elseif #record.players == 0 then
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

    if isExpanded then
        for playerIndex = playerCount + 1, #card.playerRows do
            card.playerRows[playerIndex]:Hide()
        end
    end

    card:Show()
    return cardHeight
end

function MainWindow:Refresh()
    if not self.frame then
        return
    end

    local records = ns.RollTracker:GetDisplayRecords()
    self:PreserveExpandedState(records)
    local cardWidth = math.max(186, self.frame:GetWidth() - 22)
    local offset = 0
    local visibleRecordKeys = {}

    for index, record in ipairs(records) do
        local card = self.cards[index] or self:CreateCard()
        self.cards[index] = card
        visibleRecordKeys[self:GetRecordKey(record)] = true
        offset = offset + self:RenderCard(card, record, offset, cardWidth) + 1
    end

    for index = #records + 1, #self.cards do
        self.cards[index]:Hide()
    end
    for recordKey in pairs(self.expandedRecords) do
        if not visibleRecordKeys[recordKey] then
            self.expandedRecords[recordKey] = nil
        end
    end

    self.emptyText:SetShown(#records == 0)
    self.scrollChild:SetSize(cardWidth, math.max(1, offset))
    self:UpdateScrollBar()
end

function MainWindow:UpdateScrollBar()
    if not self.scrollFrame or not self.scrollBar then
        return
    end

    local maxScroll = math.max(
        0,
        self.scrollChild:GetHeight() - self.scrollFrame:GetHeight()
    )
    local currentScroll = math.min(self.scrollFrame:GetVerticalScroll() or 0, maxScroll)
    self.maxScroll = maxScroll

    self.scrollBar:SetMinMaxValues(0, math.max(1, maxScroll))
    self.scrollFrame:SetVerticalScroll(currentScroll)
    self.scrollBar:SetValue(currentScroll)
    self.scrollBar:SetShown(maxScroll > 0)
    self.scrollTrack:SetShown(maxScroll > 0)
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
    frame:SetAlpha(settings.opacity)
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
    SetBackdrop(frame, { 0.018, 0.022, 0.029, 0.96 })
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

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", 1, 0)

    local optionsButton = CreateFrame("Button", nil, frame)
    optionsButton:SetSize(16, 16)
    optionsButton:SetPoint("RIGHT", closeButton, "LEFT", -1, 0)
    optionsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    optionsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    optionsButton:GetHighlightTexture():SetAlpha(0.35)
    optionsButton:SetScript("OnClick", function()
        ns.Options:Show()
    end)
    optionsButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(ns.L.OPTIONS)
        GameTooltip:Show()
    end)
    optionsButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local topBar = frame:CreateTexture(nil, "BACKGROUND")
    topBar:SetColorTexture(0.09, 0.11, 0.14, 0.72)
    topBar:SetPoint("TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", -1, -1)
    topBar:SetHeight(21)

    local dragArea = CreateFrame("Frame", nil, frame)
    dragArea:SetPoint("TOPLEFT", 2, -2)
    dragArea:SetPoint("TOPRIGHT", optionsButton, "TOPLEFT", -2, 0)
    dragArea:SetHeight(19)
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
    divider:SetColorTexture(0.25, 0.32, 0.42, 0.55)
    divider:SetPoint("TOPLEFT", 1, -22)
    divider:SetPoint("TOPRIGHT", -1, -22)
    divider:SetHeight(1)

    local scrollFrame = CreateFrame("ScrollFrame", "BetterLootRollsScrollFrame", frame)
    self.scrollFrame = scrollFrame
    scrollFrame:SetPoint("TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -17, 7)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    self.scrollChild = scrollChild
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local scrollBar = CreateFrame("Slider", nil, frame)
    self.scrollBar = scrollBar
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetWidth(10)
    scrollBar:SetPoint("TOPRIGHT", -3, -28)
    scrollBar:SetPoint("BOTTOMRIGHT", -3, 9)
    scrollBar:SetValueStep(1)
    scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = scrollBar:GetThumbTexture()
    thumb:SetSize(10, 32)
    thumb:SetColorTexture(0.36, 0.57, 0.82, 0.9)

    local scrollTrack = frame:CreateTexture(nil, "BACKGROUND")
    self.scrollTrack = scrollTrack
    scrollTrack:SetWidth(3)
    scrollTrack:SetPoint("TOP", scrollBar, "TOP")
    scrollTrack:SetPoint("BOTTOM", scrollBar, "BOTTOM")
    scrollTrack:SetColorTexture(0.18, 0.22, 0.28, 0.5)

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetVerticalScroll(math.max(0, math.min(self.maxScroll or 0, value)))
    end)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = self.maxScroll or 0
        local currentScroll = scrollFrame:GetVerticalScroll() or 0
        local targetScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * 32)))
        scrollBar:SetValue(targetScroll)
    end)

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.emptyText = emptyText
    emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 10)
    emptyText:SetText(ns.L.NO_ROLLS)

    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(13, 13)
    resizeButton:SetPoint("BOTTOMRIGHT", -1, 1)
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
