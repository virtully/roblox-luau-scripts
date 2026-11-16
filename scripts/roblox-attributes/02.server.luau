--!strict
-- How to use attributes in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-attributes
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Levels
-- Script in ServerScriptService named Levels.
-- Keeps a Level attribute on each player; the client shows it.
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player: Player)
	player:SetAttribute("Level", 1)
	-- for this example: level up every 30 seconds
	while player.Parent do
		task.wait(30)
		local level = player:GetAttribute("Level")
		if typeof(level) == "number" then
			player:SetAttribute("Level", level + 1)
		end
	end
end)
