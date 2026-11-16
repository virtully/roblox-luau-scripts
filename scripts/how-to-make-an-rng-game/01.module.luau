--!strict
-- How to make an RNG game in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-rng-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named Auras
-- ModuleScript in ReplicatedStorage named Auras.
-- One table drives the roll on the server and the odds the client shows, so they always match.
export type Aura = { name: string, weight: number }

local LIST: { Aura } = {
	{ name = "Common Glow", weight = 600 },
	{ name = "Ember", weight = 250 },
	{ name = "Frostbite", weight = 120 },
	{ name = "Stormcaller", weight = 25 },
	{ name = "Eclipse", weight = 4.9 },
	{ name = "Void Crown", weight = 0.1 },
}
local LUCK_FROM = 25 -- luck multiplies every aura this rare or rarer (weight at or below)

local Auras = {}
Auras.LIST = LIST

local function weightOf(aura: Aura, luck: number): number
	return if aura.weight <= LUCK_FROM then aura.weight * luck else aura.weight
end

-- Each aura's chance in percent for a player with this luck. They add up to 100.
function Auras.odds(luck: number): { [string]: number }
	local total = 0
	for _, aura in LIST do
		total += weightOf(aura, luck)
	end
	local result = {}
	for _, aura in LIST do
		result[aura.name] = weightOf(aura, luck) / total * 100
	end
	return result
end

-- Shows a percentage with four more decimal places than its first non-zero digit
function Auras.formatPercent(percent: number): string
	local places = if percent >= 1 then 4 else -math.floor(math.log10(percent)) + 4
	return string.format("%." .. places .. "f%%", percent)
end

-- The roll itself. Only the server calls this.
function Auras.roll(rng: Random, luck: number): string
	local total = 0
	for _, aura in LIST do
		total += weightOf(aura, luck)
	end
	local pick = rng:NextNumber(0, total)
	for _, aura in LIST do
		pick -= weightOf(aura, luck)
		if pick <= 0 then
			return aura.name
		end
	end
	return LIST[#LIST].name
end

return Auras
