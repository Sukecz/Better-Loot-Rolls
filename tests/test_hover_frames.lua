local ns = {}
for _, file in ipairs({ "Locales/enUS.lua", "Defaults.lua", "ApiCompat.lua", "MainWindow.lua" }) do
    assert(loadfile(file))("BetterLootRolls", ns)
end
local function Node()
    local node = { scripts = {}, visible = true }
    function node:SetScript(event, handler) self.scripts[event] = handler end
    function node:GetScript(event) return self.scripts[event] end
    function node:SetText(text) self.text = text end
    function node:SetTexture(texture) self.texture = texture end
    function node:Show() self.visible = true end
    function node:Hide()
        self.visible = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function node:SetShown(show) if show then self:Show() else self:Hide() end end
    node.CreateTexture = Node
    node.CreateFontString = Node
    return setmetatable(node, { __index = function(_, key)
        if key:match("^Set") or key == "ClearAllPoints" or key == "RegisterForClicks" then
            return function() end
        end
        error("Unexpected frame method: " .. key)
    end })
end
CreateFrame = Node
local owner, text, tooltipShown
GameTooltip = {
    SetOwner = function(_, value) owner = value end,
    IsOwned = function(_, value) return owner == value end,
    SetText = function(_, value) text = value end,
    SetHyperlink = function(_, value) text = value end,
    AddLine = function() end,
    AddDoubleLine = function() end,
    Show = function() tooltipShown = true end,
    Hide = function() owner = nil; tooltipShown = false end,
}
ns.ApiCompat.GetItemTexture = function() return 123 end
IsModifiedClick = function() return false end
local card = ns.MainWindow:CreateCard()
local record = { rollID = 1, itemLink = "item:123", isDone = true, players = {
    { name = "Me", isMe = true, choice = "GREED", roll = 100 },
    { name = "Winner", isWinner = true, choice = "NEED", roll = 20 },
} }
ns.MainWindow:RenderCard(card, record, 0, 118, true)
assert(card.status.text:find("Dice-Up", 1, true))
assert(card.ownChoiceIcon.texture:find("Coin-Up", 1, true))
card.ownChoiceButton.scripts.OnEnter()
assert(text == "Your roll: Greed" and tooltipShown)
record.players[1].choice = "NEED"
ns.MainWindow:RenderCard(card, record, 0, 118, true)
assert(text == "Your roll: Need")
card.itemButton.scripts.OnEnter()
assert(text == "item:123")
record.itemLink = "item:456"
ns.MainWindow:RenderCard(card, record, 0, 118, true)
assert(text == "item:456")
card:Hide()
assert(not tooltipShown)
local refreshed = false
ns.MainWindow.Refresh = function() refreshed = true end
card.ownChoiceButton.scripts.OnClick()
assert(refreshed and ns.MainWindow.expandedRecords[card.recordKey])
record.players[1].choice = "GREED"
ns.MainWindow:RenderCard(card, record, 0, 280, false)
assert(card.playerRows[1].name.text:find("Winner", 1, true))
card.scripts.OnEnter(card)
assert(owner == card and tooltipShown)
card:Hide()
assert(not tooltipShown)
print("test_hover_frames.lua: ok")
