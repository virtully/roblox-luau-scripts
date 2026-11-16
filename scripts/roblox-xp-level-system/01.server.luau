--!strict
-- How to make an XP and level system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-xp-level-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FormulaTest
-- XP needed to go from this level to the next one
local BASE_XP = 100
local GROWTH = 1.5

local function xpForLevel(level: number): number
	return math.floor(BASE_XP * level ^ GROWTH)
end

print(xpForLevel(1)) --> 100
print(xpForLevel(10)) --> 3162
