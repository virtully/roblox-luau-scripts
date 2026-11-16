--!strict
-- How to make a rebirth system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-rebirth-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CoinIncome
-- Script in ServerScriptService named CoinIncome.
-- Pays every player a few coins each second, multiplied by their rebirths.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local COINS_PER_SECOND = 5

local awardCoins = ServerStorage:WaitForChild("AwardCoins") :: BindableEvent

while true do
	task.wait(1)
	for _, player in Players:GetPlayers() do
		awardCoins:Fire(player, COINS_PER_SECOND)
	end
end
