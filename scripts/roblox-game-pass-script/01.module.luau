--!strict
-- Roblox game pass script: sell perks the right way
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-game-pass-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named PassConfig
-- Every pass the game sells, by name. The server and LocalScripts both read this.
local PassConfig = {}

-- Paste each pass ID from Creator Hub in place of 0.
-- A pass left at 0 is skipped, so you can set them up one at a time.
local ids: { [string]: number } = {
	VIP = 0, -- walk through the VIP door
	Speed = 0, -- walk faster
	GravityCoil = 0, -- a Tool kept in ServerStorage.PassItems
}
PassConfig.ids = ids

-- The Player attribute the server sets to true once a player owns the pass
function PassConfig.attributeFor(passName: string): string
	return "OwnsPass_" .. passName
end

return PassConfig
