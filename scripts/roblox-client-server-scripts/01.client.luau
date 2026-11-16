--!strict
-- LocalScript vs Script vs ModuleScript in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-client-server-scripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named WhoAmIClient
local Players = game:GetService("Players")

local player = Players.LocalPlayer -- the player on this device
print(`This copy of the script belongs to {player.Name}`)
