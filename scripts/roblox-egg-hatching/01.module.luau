--!strict
-- How to make an egg hatching system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-egg-hatching
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named EggConfig
-- ModuleScript in ReplicatedStorage named EggConfig.
-- Prices and odds for every egg. The server rolls with these numbers; the client
-- only reads them to show the odds.
export type PetChance = { pet: string, weight: number, rarity: string }
export type Egg = { price: number, pets: { PetChance } }

local EggConfig: { [string]: Egg } = {
	BasicEgg = {
		price = 100,
		pets = {
			{ pet = "Dog", weight = 50, rarity = "Common" },
			{ pet = "Cat", weight = 35, rarity = "Common" },
			{ pet = "Bunny", weight = 12, rarity = "Rare" },
			{ pet = "Dragon", weight = 3, rarity = "Legendary" },
		},
	},
	GoldEgg = {
		price = 1000,
		pets = {
			{ pet = "Fox", weight = 60, rarity = "Rare" },
			{ pet = "Unicorn", weight = 35, rarity = "Epic" },
			{ pet = "Phoenix", weight = 5, rarity = "Legendary" },
		},
	},
}

return EggConfig
