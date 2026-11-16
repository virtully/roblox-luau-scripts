--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named InventoryClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

type Item = { name: string, description: string, icon: string?, toolName: string?, heal: number? }
type Catalog = { get: (id: string) -> Item? }
type Slot = { id: string, count: number }
type Snapshot = { capacity: number, slots: { Slot }, equipped: string? }

local ItemCatalog = require(ReplicatedStorage:WaitForChild("ItemCatalog")) :: Catalog
local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local inventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent
local equipItem = remotes:WaitForChild("EquipItem") :: RemoteEvent
local useItem = remotes:WaitForChild("UseItem") :: RemoteEvent

local player = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.B

local COLOURS = {
	panel = Color3.fromRGB(24, 20, 36),
	slot = Color3.fromRGB(44, 38, 64),
	empty = Color3.fromRGB(34, 30, 48),
	equipped = Color3.fromRGB(124, 77, 255),
	text = Color3.fromRGB(240, 238, 245),
	muted = Color3.fromRGB(170, 165, 185),
}

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function makeLabel(parent: GuiObject, text: string, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.BuilderSansBold
	label.TextColor3 = COLOURS.text
	label.TextSize = textSize
	label.Text = text
	label.Parent = parent
	return label
end

-- 1. Build the window once. ResetOnSpawn = false keeps it through respawns.
local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.Position = UDim2.new(0, 16, 0.5, 0)
openButton.Size = UDim2.fromOffset(140, 40)
openButton.BackgroundColor3 = COLOURS.panel
openButton.Font = Enum.Font.BuilderSansBold
openButton.TextColor3 = COLOURS.text
openButton.TextSize = 18
openButton.Text = "Inventory (B)"
addCorner(openButton, 8)
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.9, 0.8)
panel.BackgroundColor3 = COLOURS.panel
panel.Visible = false
addCorner(panel, 12)
panel.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(440, 400)
sizeLimit.Parent = panel

local title = makeLabel(panel, "Inventory", 22)
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 32)
title.TextXAlignment = Enum.TextXAlignment.Left

local slotCount = makeLabel(panel, "", 16)
slotCount.Position = UDim2.fromOffset(16, 8)
slotCount.Size = UDim2.new(1, -32, 0, 32)
slotCount.TextColor3 = COLOURS.muted
slotCount.TextXAlignment = Enum.TextXAlignment.Right

local grid = Instance.new("ScrollingFrame")
grid.Position = UDim2.fromOffset(12, 48)
grid.Size = UDim2.new(1, -24, 1, -100)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.CanvasSize = UDim2.new() -- AutomaticCanvasSize grows it to fit the cells
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 6
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(72, 72)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local info = makeLabel(panel, "Click an item to equip or use it.", 16)
info.AnchorPoint = Vector2.new(0, 1)
info.Position = UDim2.new(0, 16, 1, -8)
info.Size = UDim2.new(1, -32, 0, 40)
info.Font = Enum.Font.BuilderSans
info.TextColor3 = COLOURS.muted
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left

-- 2. One cell per slot. This only draws what the server sent; it never
-- changes the inventory itself.
local function makeCell(index: number, slot: Slot?, equippedId: string?)
	local cell = Instance.new("TextButton")
	cell.LayoutOrder = index
	cell.Text = ""
	cell.AutoButtonColor = slot ~= nil
	cell.BackgroundColor3 = if slot then COLOURS.slot else COLOURS.empty
	addCorner(cell, 8)
	cell.Parent = grid
	if not slot then
		return -- an empty slot
	end

	local itemId = slot.id
	local item = ItemCatalog.get(itemId)
	local name = if item then item.name else itemId

	if item and item.icon then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = item.icon
		image.Parent = cell
	else
		local nameLabel = makeLabel(cell, name, 14)
		nameLabel.Size = UDim2.fromScale(1, 1)
		nameLabel.TextWrapped = true
	end

	if slot.count > 1 then
		local countLabel = makeLabel(cell, `x{slot.count}`, 14)
		countLabel.AnchorPoint = Vector2.new(1, 1)
		countLabel.Position = UDim2.new(1, -6, 1, -4)
		countLabel.Size = UDim2.fromOffset(40, 16)
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
	end

	if itemId == equippedId then
		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.Color = COLOURS.equipped
		outline.Thickness = 3
		outline.Parent = cell
	end

	cell.MouseEnter:Connect(function()
		info.Text = if item then `{item.name}: {item.description}` else name
	end)
	cell.Activated:Connect(function()
		-- Ask, never tell: the server checks the request and sends back the result
		if item and item.toolName then
			equipItem:FireServer(itemId)
		elseif item and item.heal then
			useItem:FireServer(itemId)
		end
	end)
end

local function render(snapshot: Snapshot)
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	for index = 1, snapshot.capacity do
		makeCell(index, snapshot.slots[index], snapshot.equipped)
	end
	slotCount.Text = `{#snapshot.slots} / {snapshot.capacity} slots`
end

-- The server fires this after loading and after every change
inventoryUpdated.OnClientEvent:Connect(render)

-- 3. Open and close with the button or the B key
local function toggle()
	panel.Visible = not panel.Visible
end

openButton.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent and input.KeyCode == TOGGLE_KEY then
		toggle()
	end
end)
