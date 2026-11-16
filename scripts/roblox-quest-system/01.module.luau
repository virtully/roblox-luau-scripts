--!strict
-- How to make a quest system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-quest-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named QuestConfig
-- ModuleScript in ReplicatedStorage named QuestConfig.
-- The quests, in the order players do them. The server and the quest panel both read this.
export type Quest = {
	title: string,
	kind: "Collect" | "Defeat",
	target: string, -- the ItemName or EnemyName that counts
	amount: number,
	reward: number, -- coins
}

local quests: { Quest } = {
	{ title = "Collect 5 Apples", kind = "Collect", target = "Apple", amount = 5, reward = 50 },
	{ title = "Defeat 3 Slimes", kind = "Defeat", target = "Slime", amount = 3, reward = 100 },
	{ title = "Collect 10 Crystals", kind = "Collect", target = "Crystal", amount = 10, reward = 200 },
	{ title = "Defeat the Slime King", kind = "Defeat", target = "SlimeKing", amount = 1, reward = 500 },
}

return quests
