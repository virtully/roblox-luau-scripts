--!strict
-- How to script in Roblox Studio: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-scripting-for-beginners
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FirstScript
-- Script in ServerScriptService named FirstScript.
-- Your first Luau: variables, a function, an if statement, a loop and a table.
-- Press Play (F5) and read the results in the Output window.

-- A variable is a name that holds a value
local gameName = "Coin Run"
local coinsToWin = 3

-- A function is a named block of code you can run as often as you like.
-- name and goal are its parameters; return hands a value back to the caller.
local function describe(name: string, goal: number): string
	return `{name}: collect {goal} coins to win`
end

print(describe(gameName, coinsToWin)) --> Coin Run: collect 3 coins to win

-- An if statement runs code only when its condition is true
if coinsToWin > 5 then
	print("That is a long game")
elseif coinsToWin > 1 then
	print("That is a short game")
else
	print("One coin and you win")
end

-- A for loop repeats code a set number of times
for count = 1, coinsToWin do
	print("Coin number", count)
end

-- A table holds a list of values; this loop visits each one in order
local colours = { "Red", "Green", "Blue" }
for position, colour in colours do
	print(position, colour) --> 1 Red, then 2 Green, then 3 Blue
end
