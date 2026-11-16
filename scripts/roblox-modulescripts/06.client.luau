--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named FormatTest
-- LocalScript in StarterPlayerScripts named FormatTest.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type NumberFormatModule = {
	short: (value: number) -> string,
	commas: (value: number) -> string,
}
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat")) :: NumberFormatModule

print(NumberFormat.short(1500)) --> 1.5K
print(NumberFormat.short(2340000)) --> 2.3M
print(NumberFormat.commas(1234567)) --> 1,234,567
