--!strict
-- How to detect and kick AFK players in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-afk-kick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RoundExample
-- Example: only players who are not AFK join the round
local Players = game:GetService("Players")

local function activePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("AFK") ~= true then
			table.insert(list, player)
		end
	end
	return list
end

print(#activePlayers() .. " players are active")
