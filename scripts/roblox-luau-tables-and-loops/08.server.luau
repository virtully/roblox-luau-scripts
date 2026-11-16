--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TableReferences
-- Script in ServerScriptService named TableReferences.
local original = { "Sword" }
local sameTable = original -- not a copy: two names for one table
table.insert(sameTable, "Shield")
print(#original) --> 2: original changed too

local copy = table.clone(original) -- a real (shallow) copy
table.insert(copy, "Bow")
print(#original, #copy) --> 2 3

-- == compares whether two names point at the same table, not what is inside
print(original == sameTable) --> true
print(original == copy) --> false, even though they started with the same items
