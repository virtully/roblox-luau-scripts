--!strict
-- How to make a shop GUI in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-shop-gui
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ShopClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- What the ShopCatalog module returns, so strict type checking can check the fields we use
type ShopItem = { id: string, name: string, price: number, description: string, toolName: string }
type Catalog = {
	items: { ShopItem },
	get: (id: string) -> ShopItem?,
	ownedAttribute: (id: string) -> string,
}

local ShopCatalog = require(ReplicatedStorage:WaitForChild("ShopCatalog")) :: Catalog
local buyItem = ReplicatedStorage:WaitForChild("ShopRemotes"):WaitForChild("BuyItem") :: RemoteFunction

local player = Players.LocalPlayer

local COLOURS = {
	panel = Color3.fromRGB(24, 20, 36),
	card = Color3.fromRGB(38, 32, 56),
	accent = Color3.fromRGB(124, 77, 255),
	owned = Color3.fromRGB(70, 66, 84),
	text = Color3.fromRGB(240, 238, 245),
	muted = Color3.fromRGB(170, 165, 185),
	good = Color3.fromRGB(120, 220, 150),
}
local REGULAR = Font.fromEnum(Enum.Font.BuilderSans)
local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addPadding(parent: GuiObject, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
end

local function newLabel(parent: GuiObject, text: string, textSize: number, font: Font): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.FontFace = font
	label.TextColor3 = COLOURS.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function newButton(parent: GuiObject, text: string): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = COLOURS.accent
	button.TextColor3 = COLOURS.text
	button.FontFace = BOLD
	button.TextSize = 18
	button.Text = text
	button.Parent = parent
	addCorner(button, 8)
	return button
end

-- ScreenGui: holds everything the shop draws on the player's screen
local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false -- keep the shop when the character respawns

-- A button on the left edge that opens and closes the shop
local openButton = Instance.new("TextButton")
openButton.Name = "OpenShop"
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.Position = UDim2.new(0, 16, 0.5, 0)
openButton.Size = UDim2.fromOffset(110, 44)
openButton.BackgroundColor3 = COLOURS.accent
openButton.TextColor3 = COLOURS.text
openButton.FontFace = BOLD
openButton.TextSize = 20
openButton.Text = "Shop"
openButton.Parent = gui
addCorner(openButton, 10)

-- The shop window: centred, hidden until the player opens it
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.8, 0.75)
panel.BackgroundColor3 = COLOURS.panel
panel.Visible = false
panel.Parent = gui
addCorner(panel, 14)
addPadding(panel, 12)

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(640, 460) -- stops the window growing huge on big screens
sizeLimit.Parent = panel

local title = newLabel(panel, "Shop", 26, BOLD)
title.Size = UDim2.new(0.5, 0, 0, 32)

local coinsLabel = newLabel(panel, "Coins: ...", 20, BOLD)
coinsLabel.AnchorPoint = Vector2.new(1, 0)
coinsLabel.Position = UDim2.new(1, -44, 0, 0)
coinsLabel.Size = UDim2.new(0.5, -44, 0, 32)
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right

local closeButton = newButton(panel, "X")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.fromScale(1, 0)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.BackgroundColor3 = COLOURS.card

-- Replies from the server, such as "You need 20 more coins.", show here
local status = newLabel(panel, "", 18, REGULAR)
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.fromScale(0, 1)
status.Size = UDim2.new(1, 0, 0, 24)
status.TextColor3 = COLOURS.muted

-- ScrollingFrame: the area that scrolls when there are more cards than fit
local list = Instance.new("ScrollingFrame")
list.Name = "Items"
list.Position = UDim2.fromOffset(0, 44)
list.Size = UDim2.new(1, 0, 1, -76)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.CanvasSize = UDim2.new() -- starts at zero; AutomaticCanvasSize grows it to fit the cards
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel

-- UIGridLayout: lays the cards out in rows and wraps them to the next row
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(180, 200)
grid.CellPadding = UDim2.fromOffset(12, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local function makeCard(item: ShopItem, order: number)
	local card = Instance.new("Frame")
	card.Name = item.id
	card.LayoutOrder = order
	card.BackgroundColor3 = COLOURS.card
	card.Parent = list
	addCorner(card, 10)
	addPadding(card, 10)

	local nameLabel = newLabel(card, item.name, 20, BOLD)
	nameLabel.Size = UDim2.new(1, 0, 0, 26)

	local description = newLabel(card, item.description, 15, REGULAR)
	description.Position = UDim2.fromOffset(0, 30)
	description.Size = UDim2.new(1, 0, 1, -80)
	description.TextColor3 = COLOURS.muted
	description.TextYAlignment = Enum.TextYAlignment.Top

	local buyButton = newButton(card, "")
	buyButton.Name = "Buy"
	buyButton.AnchorPoint = Vector2.new(0, 1)
	buyButton.Position = UDim2.fromScale(0, 1)
	buyButton.Size = UDim2.new(1, 0, 0, 40)

	local ownedAttribute = ShopCatalog.ownedAttribute(item.id)
	local busy = false

	local function refresh()
		if player:GetAttribute(ownedAttribute) == true then
			buyButton.Text = "Owned"
			buyButton.BackgroundColor3 = COLOURS.owned
			buyButton.AutoButtonColor = false
		else
			buyButton.Text = `Buy: {item.price} coins`
			buyButton.BackgroundColor3 = COLOURS.accent
			buyButton.AutoButtonColor = true
		end
	end

	buyButton.Activated:Connect(function()
		if busy or player:GetAttribute(ownedAttribute) == true then
			return
		end
		busy = true
		buyButton.Text = "Buying..."

		-- Send only the item id. The server looks up the price itself.
		local ok, bought, message = pcall(function()
			return buyItem:InvokeServer(item.id)
		end)
		if ok and type(message) == "string" then
			status.Text = message
			status.TextColor3 = if bought == true then COLOURS.good else COLOURS.muted
		else
			status.Text = "The shop did not answer. Try again."
			status.TextColor3 = COLOURS.muted
		end

		busy = false
		refresh()
	end)

	-- The server sets this attribute when the purchase goes through (or when saved items load)
	player:GetAttributeChangedSignal(ownedAttribute):Connect(refresh)
	refresh()
end

for index, item in ShopCatalog.items do
	makeCard(item, index)
end

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	status.Text = ""
end)

closeButton.Activated:Connect(function()
	panel.Visible = false
end)

gui.Parent = player:WaitForChild("PlayerGui")

-- Show the player's coins. The server owns the real value; this only displays it.
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue
local function updateCoins()
	coinsLabel.Text = `Coins: {coins.Value}`
end
coins.Changed:Connect(updateCoins)
updateCoins()
