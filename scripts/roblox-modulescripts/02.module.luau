--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named GameConfig
-- ModuleScript in ReplicatedStorage named GameConfig.
-- Numbers that both server Scripts and LocalScripts need. Change them here, once.
export type Config = {
	StartingCoins: number,
	RoundSeconds: number,
	SwordPrice: number,
	MaxPlayersPerTeam: number,
}

local GameConfig: Config = {
	StartingCoins = 50,
	RoundSeconds = 180,
	SwordPrice = 250,
	MaxPlayersPerTeam = 8,
}

return GameConfig
