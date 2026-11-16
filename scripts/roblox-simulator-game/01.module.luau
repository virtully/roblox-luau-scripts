--!strict
-- How to make a simulator game on Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-simulator-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named SimulatorConfig
-- Every number in the core loop, and the formulas both sides use. The client only
-- uses these to show prices; the server uses its own copy to decide.

local SimulatorConfig = {}

SimulatorConfig.UPGRADE_BASE_COST = 10 -- price of Click Power level 2
SimulatorConfig.UPGRADE_COST_GROWTH = 1.5 -- each level costs 1.5 times the last
SimulatorConfig.MAX_POWER_LEVEL = 50
SimulatorConfig.REBIRTH_BASE_COST = 1000 -- coins needed for the first rebirth
SimulatorConfig.REBIRTH_COST_GROWTH = 3 -- each rebirth costs 3 times the last
SimulatorConfig.MAX_CLICKS_PER_SECOND = 15 -- clicks past this in one second are ignored

-- Coins for one click: the Click Power level, multiplied by 1 + the number of rebirths
function SimulatorConfig.clickValue(powerLevel: number, rebirths: number): number
	return powerLevel * (rebirths + 1)
end

-- Price of the next Click Power level
function SimulatorConfig.upgradeCost(powerLevel: number): number
	return math.floor(SimulatorConfig.UPGRADE_BASE_COST * SimulatorConfig.UPGRADE_COST_GROWTH ^ (powerLevel - 1))
end

-- Coins needed for the next rebirth
function SimulatorConfig.rebirthCost(rebirths: number): number
	return SimulatorConfig.REBIRTH_BASE_COST * SimulatorConfig.REBIRTH_COST_GROWTH ^ rebirths
end

return SimulatorConfig
