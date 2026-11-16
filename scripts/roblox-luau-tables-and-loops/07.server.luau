--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RemoveWhileLooping
-- Script in ServerScriptService named RemoveWhileLooping.
local enemies: { string } = { "Zombie", "Ghost", "Ghost", "Zombie", "Ghost" }

-- Wrong: a forward loop that removes skips the item after each removal.
-- Right: go from the end to the start, so removing never moves an item you have not checked yet.
for i = #enemies, 1, -1 do
	if enemies[i] == "Ghost" then
		table.remove(enemies, i)
	end
end
print(table.concat(enemies, ", ")) --> Zombie, Zombie
