--!strict
-- How to save player data in Roblox Studio with DataStores
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-datastore-tutorial
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named DataWarning
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local shown = false

local function showWarning()
	if shown or player:GetAttribute("DataLoaded") ~= false then
		return
	end
	shown = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "DataWarning"
	gui.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 12)
	label.Size = UDim2.new(0.8, 0, 0, 48)
	label.BackgroundColor3 = Color3.fromRGB(110, 28, 28)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = "Your saved progress could not be loaded. Nothing you do in this server will be saved, so rejoin later."
	label.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
end

-- The server sets DataLoaded once, after it tries to load this player's data
player:GetAttributeChangedSignal("DataLoaded"):Connect(showWarning)
showWarning()
