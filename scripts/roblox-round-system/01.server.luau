--!strict
-- How to make a round system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-round-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Leaderstats
local Players = game:GetService("Players")

local function setupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- must be exactly this name, all lowercase

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(setupLeaderstats)

-- In Studio you can join before this script runs, so set up anyone already here
for _, player in Players:GetPlayers() do
	setupLeaderstats(player)
end
