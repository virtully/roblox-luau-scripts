--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TopScores
-- Script in ServerScriptService named TopScores. Sorts a dictionary by copying it into an array.
local coins: { [string]: number } = { Ana = 120, Ben = 340, Chloe = 90, Dev = 340 }

type Entry = { name: string, score: number }
local ranking: { Entry } = {}
for name, score in coins do
	table.insert(ranking, { name = name, score = score })
end

table.sort(ranking, function(a: Entry, b: Entry): boolean
	if a.score ~= b.score then
		return a.score > b.score -- highest first
	end
	return a.name < b.name -- same score: alphabetical, so the order is always the same
end)

for place, entry in ranking do
	print(place, entry.name, entry.score)
end
--> 1 Ben 340, 2 Dev 340, 3 Ana 120, 4 Chloe 90
