--!strict
-- How to make a leaderboard in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-leaderboard-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Leaderstats
local Players = game:GetService("Players")

local function setupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- must be exactly this name, all lowercase

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	leaderstats.Parent = player -- parent last, once the values are inside
end

Players.PlayerAdded:Connect(setupLeaderstats)

-- In Studio you can join before this script runs, so set up anyone already here
for _, player in Players:GetPlayers() do
	setupLeaderstats(player)
end
