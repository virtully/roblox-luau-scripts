--!strict
-- How to make a leaderboard in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-leaderboard-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named CoinPad
local Players = game:GetService("Players")

local part = script.Parent :: BasePart
local REWARD = 10
local COOLDOWN_SECONDS = 1

local lastReward: { [Player]: number } = {}

part.Touched:Connect(function(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local now = os.clock()
	local last = lastReward[player]
	if last and now - last < COOLDOWN_SECONDS then
		return -- Touched fires many times per step; this stops one touch paying out ten times
	end
	lastReward[player] = now

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += REWARD
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastReward[player] = nil
end)
