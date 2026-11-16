--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DictionaryBasics
-- Script in ServerScriptService named DictionaryBasics.
local stats: { [string]: number? } = {
	Coins = 50,
	Gems = 2,
	Level = 1,
}

print(stats.Coins) --> 50
print(stats["Gems"]) --> 2: the same as stats.Gems
local key = "Level"
print(stats[key]) --> 1: square brackets let you use a variable as the key

-- Change a key, or add a new one
stats.Coins = 75
stats.Wins = 0

-- Remove a key by setting it to nil
stats.Gems = nil
print(stats.Gems) --> nil

-- # does not count dictionary keys (it would give 0 here), so count them with a loop
local count = 0
for _ in stats do
	count += 1
end
print("Keys:", count) --> Keys: 3
