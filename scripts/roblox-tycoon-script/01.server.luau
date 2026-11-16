--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Leaderstats
local Players = game:GetService("Players")

local STARTING_CASH = 0

local function setupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- must be exactly this name, all lowercase

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = STARTING_CASH
	cash.Parent = leaderstats

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(setupLeaderstats)

-- In Studio you can join before this script runs, so set up anyone already here
for _, player in Players:GetPlayers() do
	setupLeaderstats(player)
end
