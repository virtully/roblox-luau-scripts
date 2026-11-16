--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TableLoops
-- Script in ServerScriptService named TableLoops.
local fruits = { "Apple", "Banana", "Cherry" }
local prices: { [string]: number } = { Apple = 5, Banana = 3, Cherry = 8 }

-- 1. Generalized iteration: works on arrays and dictionaries
for index, fruit in fruits do
	print(index, fruit) --> 1 Apple, 2 Banana, 3 Cherry
end
for name, price in prices do
	print(name, "costs", price) -- order is not promised for dictionaries
end

-- 2. ipairs: arrays only, in order from 1, stops at the first nil
for index, fruit in ipairs(fruits) do
	print(index, fruit)
end

-- 3. pairs: any table, every key, in no promised order
for name, price in pairs(prices) do
	print(name, price)
end

-- Use _ for a value you do not need
for _, fruit in fruits do
	print("I like", fruit)
end
