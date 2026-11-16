--!strict
-- How to fix Roblox script errors
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CoinsWatcher
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Broken version:
--   local coins = player.leaderstats.Coins
-- The server creates leaderstats, and it can reach this client after this
-- script starts. Then Output shows:
--   leaderstats is not a valid member of Player "Players.YourName"

local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue -- the server makes Coins an IntValue

print(`[CoinsWatcher] starting coins: {coins.Value}`)
coins.Changed:Connect(function(newValue: number)
	print(`[CoinsWatcher] coins changed to {newValue}`)
end)
