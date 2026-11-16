--!strict
-- How to make a morph in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-morph-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in a ScreenGui in StarterGui named MorphButtons
-- LocalScript inside a ScreenGui in StarterGui, named MorphButtons.
-- One button per morph name; the server checks every name it receives.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MORPH_NAMES = { "Zombie", "Robot" } -- the names of your models in ServerStorage.Morphs

local requestMorph = ReplicatedStorage:WaitForChild("RequestMorph") :: RemoteEvent
local gui = script.Parent :: ScreenGui

local list = Instance.new("Frame")
list.AnchorPoint = Vector2.new(0, 0.5)
list.Position = UDim2.new(0, 16, 0.5, 0)
list.Size = UDim2.fromOffset(140, 0)
list.AutomaticSize = Enum.AutomaticSize.Y
list.BackgroundTransparency = 1
list.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function addButton(text: string, morphName: string, order: number)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(140, 40)
	button.LayoutOrder = order
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = list
	button.Activated:Connect(function()
		requestMorph:FireServer(morphName)
	end)
end

for index, name in MORPH_NAMES do
	addButton(name, name, index)
end
addButton("Me", "", #MORPH_NAMES + 1)
