--!strict
-- LocalScript vs Script vs ModuleScript in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-client-server-scripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named WhoAmIServer
local Players = game:GetService("Players")

print("LocalPlayer on the server:", Players.LocalPlayer) --> nil

local function onPlayerAdded(player: Player)
	print(`{player.Name} joined`) -- the event tells the server which player
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- anyone who joined before this line ran
	onPlayerAdded(player)
end
