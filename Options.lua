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

local function CreateSection(parent, titleText)
    local section = CreateBackdropFrame(nil, parent)
    if section.SetBackdrop then
        section:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        section:SetBackdropColor(0.045, 0.052, 0.065, 0.94)
        section:SetBackdropBorderColor(0.16, 0.2, 0.26, 1)
    end

    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(titleText)
    section.title = title
    return section
end

local function FormatPercent(value)
    return string.format("%d%%", math.floor((value * 100) + 0.5))
end

function Options:Apply()
    ns.Database:Set("historyLimit", self.historyEdit:GetNumber())
    ns.Database:Set("autoShow", self.autoShow:GetChecked())
    ns.Database:Set("scale", self.scaleSlider:GetValue())
    ns.Database:Set("opacity", self.opacitySlider:GetValue())
    ns.Database:PruneHistory()
    ns.MainWindow:ApplySettings()
    self:Refresh()
end

function Options:Refresh()
    self.historyEdit:SetNumber(ns.Database:Get("historyLimit"))
    self.autoShow:SetChecked(ns.Database:Get("autoShow"))
    self.scaleSlider:SetValue(ns.Database:Get("scale"))
    self.opacitySlider:SetValue(ns.Database:Get("opacity"))
    self.scaleValue:SetText(FormatPercent(ns.Database:Get("scale")))
    self.opacityValue:SetText(FormatPercent(ns.Database:Get("opacity")))
end

function Options:Initialize()
    if self.frame then
        return
    end

    local frame = CreateBackdropFrame("BetterLootRollsOptionsFrame", UIParent)
    self.frame = frame
    frame:SetSize(400, 370)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -15)
    title:SetText(ns.L.TITLE)

    local description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    description:SetText(ns.L.OPTIONS_DESCRIPTION)
    description:SetTextColor(0.62, 0.67, 0.74)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 2, 2)

    local dragArea = CreateFrame("Frame", nil, frame)
    dragArea:SetPoint("TOPLEFT", 5, -5)
    dragArea:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -2, 0)
    dragArea:SetHeight(48)
    dragArea:EnableMouse(true)
    dragArea:RegisterForDrag("LeftButton")
    dragArea:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragArea:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local historySection = CreateSection(frame, ns.L.ROLL_HISTORY)
    historySection:SetPoint("TOPLEFT", 14, -58)
    historySection:SetPoint("TOPRIGHT", -14, -58)
    historySection:SetHeight(102)

    local autoShow = CreateFrame("CheckButton", nil, historySection, "UICheckButtonTemplate")
    self.autoShow = autoShow
    autoShow:SetPoint("TOPLEFT", 7, -27)
    autoShow.text:SetText(ns.L.AUTO_SHOW)

    local historyLabel = historySection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    historyLabel:SetPoint("TOPLEFT", 12, -62)
    historyLabel:SetText(ns.L.HISTORY_LIMIT)

    local historyHint = historySection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    historyHint:SetPoint("TOPLEFT", historyLabel, "BOTTOMLEFT", 0, -2)
    historyHint:SetText(ns.L.HISTORY_RANGE)
    historyHint:SetTextColor(0.52, 0.57, 0.64)

    local historyEdit = CreateFrame("EditBox", nil, historySection, "InputBoxTemplate")
    self.historyEdit = historyEdit
    historyEdit:SetSize(55, 24)
    historyEdit:SetPoint("TOPRIGHT", -13, -57)
    historyEdit:SetAutoFocus(false)
    historyEdit:SetNumeric(true)
    historyEdit:SetMaxLetters(3)
    historyEdit:SetScript("OnEnterPressed", function()
        self:Apply()
        historyEdit:ClearFocus()
    end)

    local appearanceSection = CreateSection(frame, ns.L.APPEARANCE)
    appearanceSection:SetPoint("TOPLEFT", 14, -170)
    appearanceSection:SetPoint("TOPRIGHT", -14, -170)
    appearanceSection:SetHeight(146)

    local scaleLabel = appearanceSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scaleLabel:SetPoint("TOPLEFT", 12, -34)
    scaleLabel:SetText(ns.L.WINDOW_SCALE)

    local scaleValue = appearanceSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.scaleValue = scaleValue
    scaleValue:SetPoint("TOPRIGHT", -12, -34)
    scaleValue:SetJustifyH("RIGHT")

    local scaleSlider = CreateFrame("Slider", nil, appearanceSection, "OptionsSliderTemplate")
    self.scaleSlider = scaleSlider
    scaleSlider:SetPoint("TOPLEFT", 20, -57)
    scaleSlider:SetWidth(320)
    scaleSlider:SetMinMaxValues(0.75, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider.Low:SetText("75%")
    scaleSlider.High:SetText("150%")
    scaleSlider.Text:SetText("")
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        scaleValue:SetText(FormatPercent(value))
    end)

    local opacityLabel = appearanceSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    opacityLabel:SetPoint("TOPLEFT", 12, -94)
    opacityLabel:SetText(ns.L.WINDOW_OPACITY)

    local opacityValue = appearanceSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.opacityValue = opacityValue
    opacityValue:SetPoint("TOPRIGHT", -12, -94)
    opacityValue:SetJustifyH("RIGHT")

    local opacitySlider = CreateFrame("Slider", nil, appearanceSection, "OptionsSliderTemplate")
    self.opacitySlider = opacitySlider
    opacitySlider:SetPoint("TOPLEFT", 20, -117)
    opacitySlider:SetWidth(320)
    opacitySlider:SetMinMaxValues(0.2, 1)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider.Low:SetText("20%")
    opacitySlider.High:SetText("100%")
    opacitySlider.Text:SetText("")
    opacitySlider:SetScript("OnValueChanged", function(_, value)
        opacityValue:SetText(FormatPercent(value))
        if ns.MainWindow.frame then
            ns.MainWindow.frame:SetAlpha(value)
        end
    end)

    local applyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    applyButton:SetSize(90, 24)
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
    frame:SetScript("OnHide", function()
        if ns.MainWindow.frame then
            ns.MainWindow.frame:SetAlpha(ns.Database:Get("opacity"))
        end
    end)
end

function Options:Show()
    self.frame:Show()
end
