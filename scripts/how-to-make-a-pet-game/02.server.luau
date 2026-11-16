--!strict
-- How to make a pet game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-pet-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named EggPolicy
-- Script in ServerScriptService named EggPolicy.
-- Reads each player's policy once, so the egg shop and the trade menu can check it.
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")

local function readPolicy(player: Player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	-- If the call fails, treat the player as restricted until it succeeds
	local restricted = true
	local tradingAllowed = false
	if ok and type(info) == "table" then
		restricted = info.ArePaidRandomItemsRestricted == true
		tradingAllowed = info.IsPaidItemTradingAllowed == true
	end
	player:SetAttribute("PaidEggsRestricted", restricted)
	player:SetAttribute("PaidTradingAllowed", tradingAllowed)
end

Players.PlayerAdded:Connect(readPolicy)
for _, player in Players:GetPlayers() do
	task.spawn(readPolicy, player)
end

-- In the server code that sells an egg for Robux, or for a currency players can buy:
-- if player:GetAttribute("PaidEggsRestricted") ~= false then
--     refuse, and offer the earnable egg or a direct purchase instead
-- end
