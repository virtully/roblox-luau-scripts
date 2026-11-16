--!strict
-- Roblox shift to sprint script for PC, mobile and console
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sprint-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named MovementConfig
-- One set of numbers for the movement LocalScript and the server's speed check.

local MovementConfig = {
	SPRINT_BONUS = 10, -- added to the current WalkSpeed: 16 (Roblox's default) becomes 26

	MAX_STAMINA = 100,
	DRAIN_PER_SECOND = 20, -- 5 seconds of sprinting from full
	REGEN_PER_SECOND = 15,
	REGEN_DELAY = 1, -- seconds after sprinting stops before stamina comes back
	MIN_TO_START = 20, -- stamina needed to start sprinting, so an empty bar cannot flicker on and off

	DASH_SPEED = 60, -- studs per second during a dash
	DASH_SECONDS = 0.2, -- so a dash covers about 12 studs
	DASH_COST = 25, -- stamina
	DASH_COOLDOWN = 1,
}

return MovementConfig
