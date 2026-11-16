--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LoopBasics
-- Script in ServerScriptService named LoopBasics.
-- Numeric for: start, stop, and an optional step
for i = 1, 5 do
	print("Countdown step", i)
end
for i = 10, 0, -2 do
	print(i) --> 10, 8, 6, 4, 2, 0
end

-- while: repeats as long as the condition is true. Checks before each run.
local health = 100
while health > 0 do
	health -= 30
end
print("Health ended at", health) --> -20

-- repeat ... until: runs at least once, checks after each run
local tries = 0
repeat
	tries += 1
until tries >= 3
print("Tried", tries, "times")

-- break leaves a loop early; continue skips to the next round
for i = 1, 10 do
	if i % 2 == 0 then
		continue -- skip even numbers
	end
	if i > 7 then
		break -- stop completely
	end
	print("Odd:", i) --> 1, 3, 5, 7
end
