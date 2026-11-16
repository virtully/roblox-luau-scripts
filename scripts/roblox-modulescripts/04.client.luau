--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ConfigTestClient
-- LocalScript in StarterPlayerScripts named ConfigTestClient.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Config = {
	StartingCoins: number,
	RoundSeconds: number,
	SwordPrice: number,
	MaxPlayersPerTeam: number,
}
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig")) :: Config

print("Client: a sword costs", GameConfig.SwordPrice)
