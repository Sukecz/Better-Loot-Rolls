local _, ns = ...

local Options = {}
ns.Options = Options

local function CreateBackdropFrame(name, parent)
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", name, parent, template)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.02, 0.02, 0.02, 0.98)
    end
    return frame
end

function Options:Apply()
    ns.Database:Set("historyLimit", self.historyEdit:GetNumber())
    ns.Database:Set("autoShow", self.autoShow:GetChecked())
    ns.Database:Set("scale", self.scaleSlider:GetValue())
    ns.Database:PruneHistory()
    ns.MainWindow:ApplySettings()
    self:Refresh()
end

function Options:Refresh()
    self.historyEdit:SetNumber(ns.Database:Get("historyLimit"))
    self.autoShow:SetChecked(ns.Database:Get("autoShow"))
    self.scaleSlider:SetValue(ns.Database:Get("scale"))
end

function Options:Initialize()
    if self.frame then
        return
    end

    local frame = CreateBackdropFrame("BetterLootRollsOptionsFrame", UIParent)
    self.frame = frame
    frame:SetSize(360, 245)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetText(ns.L.TITLE .. " - " .. ns.L.OPTIONS)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 2, 2)

    local historyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    historyLabel:SetPoint("TOPLEFT", 18, -58)
    historyLabel:SetText(ns.L.HISTORY_LIMIT)

    local historyEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.historyEdit = historyEdit
    historyEdit:SetSize(55, 24)
    historyEdit:SetPoint("LEFT", historyLabel, "RIGHT", 14, 0)
    historyEdit:SetAutoFocus(false)
    historyEdit:SetNumeric(true)
    historyEdit:SetMaxLetters(3)
    historyEdit:SetScript("OnEnterPressed", function()
        self:Apply()
        historyEdit:ClearFocus()
    end)

    local autoShow = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    self.autoShow = autoShow
    autoShow:SetPoint("TOPLEFT", 14, -88)
    autoShow.text:SetText(ns.L.AUTO_SHOW)

    local scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scaleLabel:SetPoint("TOPLEFT", 18, -132)
    scaleLabel:SetText(ns.L.WINDOW_SCALE)

    local scaleSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    self.scaleSlider = scaleSlider
    scaleSlider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 4, -14)
    scaleSlider:SetWidth(190)
    scaleSlider:SetMinMaxValues(0.75, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider.Low:SetText("75%")
    scaleSlider.High:SetText("150%")
    scaleSlider.Text:SetText("")

    local applyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    applyButton:SetSize(80, 24)
    applyButton:SetPoint("BOTTOMRIGHT", -14, 14)
    applyButton:SetText(ns.L.APPLY)
    applyButton:SetScript("OnClick", function()
        self:Apply()
    end)

    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(105, 24)
    clearButton:SetPoint("BOTTOMLEFT", 14, 14)
    clearButton:SetText(ns.L.CLEAR_HISTORY)
    clearButton:SetScript("OnClick", function()
        ns.Database:ClearHistory()
        ns.MainWindow:Refresh()
    end)

    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(105, 24)
    resetButton:SetPoint("LEFT", clearButton, "RIGHT", 7, 0)
    resetButton:SetText(ns.L.RESET_WINDOW)
    resetButton:SetScript("OnClick", function()
        ns.Database:ResetWindow()
        ns.MainWindow:ApplySettings()
        self:Refresh()
    end)

    frame:SetScript("OnShow", function()
        self:Refresh()
    end)
end

function Options:Show()
    self.frame:Show()
end
