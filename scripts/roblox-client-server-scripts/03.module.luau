--!strict
-- LocalScript vs Script vs ModuleScript in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-client-server-scripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named RewardSettings
-- Shared by RewardServer (which pays out) and RewardClient (which shows the timing).
-- Every player receives a copy of this module, so keep secrets out of it.
local RewardSettings = {
	AMOUNT = 25, -- coins per claim
	COOLDOWN = 30, -- seconds between claims
}

return RewardSettings
