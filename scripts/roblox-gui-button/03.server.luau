--!strict
-- How to make a GUI button that opens a menu in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gui-button
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ClaimRewardServer
-- Script in ServerScriptService named ClaimRewardServer.
-- Gives 50 coins once per player per server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimReward = ReplicatedStorage:WaitForChild("ClaimReward") :: RemoteEvent
local claimed: { [Player]: boolean } = {}

claimReward.OnServerEvent:Connect(function(player: Player)
	if claimed[player] then
		return -- the button can be fired again by a cheater; the server says no
	end
	claimed[player] = true
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += 50
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	claimed[player] = nil
end)
