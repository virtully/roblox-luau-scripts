--!strict
-- How to make a round system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-round-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GiveRoundTool
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local toolTemplate = ServerStorage:WaitForChild("RoundTool") :: Tool

local function watchPlayer(player: Player)
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		if player:GetAttribute("InRound") ~= true then
			return
		end
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			toolTemplate:Clone().Parent = backpack
		end
	end)
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in Players:GetPlayers() do
	watchPlayer(player)
end
