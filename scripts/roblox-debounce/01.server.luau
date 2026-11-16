--!strict
-- How to use a debounce in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-debounce
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named TouchCounter
-- Script inside a Part. Step on it once and count the prints.
local pad = script.Parent :: BasePart

pad.Touched:Connect(function(hit: BasePart)
	print("Touched by", hit.Name)
end)
