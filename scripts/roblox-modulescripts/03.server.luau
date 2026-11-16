--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ConfigTest
-- Script in ServerScriptService named ConfigTest.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Config = {
	StartingCoins: number,
	RoundSeconds: number,
	SwordPrice: number,
	MaxPlayersPerTeam: number,
}
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig")) :: Config

print("Server: a sword costs", GameConfig.SwordPrice)
