--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ArrayBasics
-- Script in ServerScriptService named ArrayBasics. Press Play and read the Output.
local weapons: { string } = { "Sword", "Bow", "Staff" }

print(weapons[1]) --> Sword
print(weapons[3]) --> Staff
print(weapons[4]) --> nil: there is no fourth item
print(#weapons) --> 3: the # operator counts the items

-- Add to the end
table.insert(weapons, "Axe")
-- Add at a position: everything after it moves up one
table.insert(weapons, 1, "Fists")
print(table.concat(weapons, ", ")) --> Fists, Sword, Bow, Staff, Axe

-- Remove by position: everything after it moves down one
local removed = table.remove(weapons, 2)
print("Removed", removed) --> Removed Sword

-- Find the position of a value (nil if it is not there)
local index = table.find(weapons, "Bow")
print("Bow is at", index) --> Bow is at 2

-- Change an item
weapons[1] = "Gloves"
print(table.concat(weapons, ", ")) --> Gloves, Bow, Staff, Axe
