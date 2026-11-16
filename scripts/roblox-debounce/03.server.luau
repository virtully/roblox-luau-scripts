--!strict
-- How to use a debounce in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-debounce
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the CoinPad part named CoinPad
-- Script inside a Part named CoinPad.
-- Gives coins on touch, at most once every COOLDOWN_SECONDS per player.
local Players = game:GetService("Players")

local pad = script.Parent :: BasePart

local COOLDOWN_SECONDS = 5
local COINS = 10

local lastPaid: { [Player]: number } = {}

pad.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	if not player then
		return -- an NPC or a loose part
	end
	local now = os.clock()
	if now - (lastPaid[player] or 0) < COOLDOWN_SECONDS then
		return -- this player was paid recently
	end
	lastPaid[player] = now

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += COINS
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastPaid[player] = nil -- do not keep players who left
end)
