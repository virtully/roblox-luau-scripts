--!strict
-- How to fix Roblox script errors
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Welcome
local Players = game:GetService("Players")

local function onPlayerAdded(player: Player)
	print(`[Welcome] {player.Name} joined`)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Players who were already here when the line above ran never fire
-- PlayerAdded for this script, so handle them now
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
