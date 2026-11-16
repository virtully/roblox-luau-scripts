--!strict
-- How to use AI in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-use-ai-in-roblox-studio
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the LavaFloor Part in Workspace named KillOnTouch
local Players = game:GetService("Players")

local lava = script.Parent :: BasePart

lava.Touched:Connect(function(hit: BasePart)
	-- Only react to parts of a player's character, not NPCs or loose parts
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character or not Players:GetPlayerFromCharacter(character) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end)
