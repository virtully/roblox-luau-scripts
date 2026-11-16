--!strict
-- How to make a teleporter in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-teleporter-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named TeleportMenu
-- LocalScript in StarterPlayer > StarterPlayerScripts named TeleportMenu.
-- A Teleport button that opens a list of spots. The list comes from the server, and
-- pressing a spot only sends its name: the server decides whether you may go.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getSpots = ReplicatedStorage:WaitForChild("GetTeleportSpots") :: RemoteFunction
local teleportRequest = ReplicatedStorage:WaitForChild("TeleportRequest") :: RemoteEvent
local player = Players.LocalPlayer

local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)
local PURPLE = Color3.fromRGB(124, 77, 255)

type Spot = { name: string, winsNeeded: number }

local function makeButton(text: string, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = PURPLE
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.FontFace = BOLD
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportMenu"
gui.ResetOnSpawn = false

local openButton = makeButton("Teleport", gui)
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.Position = UDim2.new(0, 12, 0.5, 0)
openButton.Size = UDim2.fromOffset(130, 44)

local panel = Instance.new("ScrollingFrame")
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Position = UDim2.new(0, 152, 0.5, 0)
panel.Size = UDim2.fromOffset(220, 260)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
panel.BackgroundTransparency = 0.1
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.CanvasSize = UDim2.new()
panel.ScrollBarThickness = 6
panel.Visible = false
panel.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = panel

gui.Parent = player:WaitForChild("PlayerGui")

local function winsOf(): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	return if wins and wins:IsA("IntValue") then wins.Value else 0
end

-- Ask the server for the spots and draw one button for each
local refreshCount = 0
local function refresh()
	refreshCount += 1
	local thisRefresh = refreshCount
	local ok, spots = pcall(function()
		return getSpots:InvokeServer() :: { Spot }
	end)
	if not ok or thisRefresh ~= refreshCount then
		return -- failed, or the menu was reopened while the server answered
	end
	for _, child in panel:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for index, spot in spots do
		local locked = winsOf() < spot.winsNeeded
		local button = makeButton(if locked then `{spot.name} (needs {spot.winsNeeded} wins)` else spot.name, panel)
		button.LayoutOrder = index
		button.Size = UDim2.new(1, 0, 0, 40)
		if locked then
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 80) -- the server checks the wins again anyway
		end
		button.Activated:Connect(function()
			teleportRequest:FireServer(spot.name)
			panel.Visible = false
		end)
	end
end

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
	end
end)
