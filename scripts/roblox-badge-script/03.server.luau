--!strict
-- How to make and award a badge in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-badge-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SummitBadge
-- Script in ServerScriptService named SummitBadge.
-- Awards a badge to players who touch the part named Summit, such as the end of an obby.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

type BadgesModule = { award: (Player, number) -> () }
local Badges = require(ServerScriptService:WaitForChild("Badges")) :: BadgesModule

local SUMMIT_BADGE_ID = 0 -- paste your badge ID
local summit = workspace:WaitForChild("Summit") :: BasePart

summit.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player and humanoid and humanoid.Health > 0 then
		Badges.award(player, SUMMIT_BADGE_ID)
	end
end)
