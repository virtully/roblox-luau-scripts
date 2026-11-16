--!strict
-- How to make and award a badge in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-badge-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CoinBadge
-- Script in ServerScriptService named CoinBadge.
-- Awards a badge when a player's Coins reach 1,000.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

type BadgesModule = { award: (Player, number) -> () }
local Badges = require(ServerScriptService:WaitForChild("Badges")) :: BadgesModule

local RICH_BADGE_ID = 0 -- paste your badge ID
local GOAL = 1000

Players.PlayerAdded:Connect(function(player: Player)
	local leaderstats = player:WaitForChild("leaderstats", 30)
	local coins = leaderstats and leaderstats:WaitForChild("Coins", 30)
	if not (coins and coins:IsA("IntValue")) then
		return
	end
	local function check()
		if coins.Value >= GOAL then
			Badges.award(player, RICH_BADGE_ID)
		end
	end
	coins.Changed:Connect(check)
	check()
end)
