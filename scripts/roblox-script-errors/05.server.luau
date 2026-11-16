--!strict
-- How to fix Roblox script errors
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CoinDrip
local Players = game:GetService("Players")

local REWARD = 5
local INTERVAL_SECONDS = 60

local function addCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not (coins and coins:IsA("IntValue")) then
		-- Say why nothing happened, instead of failing silently
		warn(`[CoinDrip] {player.Name} has no leaderstats.Coins yet`)
		return
	end

	-- Broken version:
	--   coins = coins + amount
	-- coins is the IntValue object, not its number, so Output shows:
	--   attempt to perform arithmetic (add) on Instance and number
	coins.Value += amount
end

-- Every minute, give each player in the server a few coins
while true do
	task.wait(INTERVAL_SECONDS)
	for _, player in Players:GetPlayers() do
		addCoins(player, REWARD)
	end
end
