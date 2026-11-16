--!strict
-- How to use CollectionService tags in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-collectionservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SpeedExample
-- In a setup function: read a per-part setting, with a default.
local function speedOf(part: BasePart): number
	local value = part:GetAttribute("Speed")
	return if typeof(value) == "number" then value else 90
end

local part = Instance.new("Part")
part:SetAttribute("Speed", 180)
print(speedOf(part)) -- 180
