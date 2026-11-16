--!strict
-- How to make character customization in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-character-customization
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CustomizeMenu
-- LocalScript in StarterPlayerScripts named CustomizeMenu.
-- Skin colour swatches and height buttons. Each click asks the server to change the look.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local changeEvent = ReplicatedStorage:WaitForChild("ChangeLook") :: RemoteEvent

-- The same colours as the server's SKIN_COLORS, in the same order, for the swatches
local SWATCHES: { Color3 } = {
	Color3.fromRGB(255, 220, 177),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(90, 56, 37),
	Color3.fromRGB(110, 170, 255),
}
local HEIGHTS = { 0.9, 1, 1.1 }

local gui = Instance.new("ScreenGui")
gui.Name = "CustomizeGui"
gui.ResetOnSpawn = false
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 12, 1, -12)
panel.Size = UDim2.fromOffset(300, 120)
panel.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local function addButton(position: UDim2, size: UDim2, color: Color3, text: string, onClick: () -> ())
	local b = Instance.new("TextButton")
	b.Position = position
	b.Size = size
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	b.Activated:Connect(onClick)
	b.Parent = panel
end

for i, color in SWATCHES do
	addButton(UDim2.fromOffset(12 + (i - 1) * 46, 14), UDim2.fromOffset(38, 38), color, "", function()
		changeEvent:FireServer("skin", i)
	end)
end
for i, height in HEIGHTS do
	local label = if height < 1 then "Short" elseif height > 1 then "Tall" else "Normal"
	addButton(UDim2.fromOffset(12 + (i - 1) * 94, 66), UDim2.fromOffset(86, 40), Color3.fromRGB(110, 80, 220), label, function()
		changeEvent:FireServer("height", height)
	end)
end

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
