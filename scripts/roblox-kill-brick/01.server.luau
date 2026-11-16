--!strict
-- How to make a kill brick (lava) in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-brick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the part named KillScript
-- Script inside the part you want to kill players, named KillScript.
local part = script.Parent :: BasePart

part.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)
