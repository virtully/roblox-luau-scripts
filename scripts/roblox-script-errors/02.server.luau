--!strict
-- How to fix Roblox script errors
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named KillBrick
local part = script.Parent :: BasePart

part.Touched:Connect(function(hit: BasePart)
	-- Broken version:
	--   hit.Parent:FindFirstChild("Humanoid").Health = 0
	-- When the touching part is not a body part of a character, FindFirstChild
	-- returns nil and Output shows:
	--   attempt to index nil with 'Health'

	-- Fixed: check each step before using it
	local model = hit:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)
