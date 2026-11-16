--!strict
-- How to make a kill feed and kill counter in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-feed
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Tool named SwordDamage
-- Script inside a Tool (with a part named Handle), named SwordDamage.
-- Damages what the blade touches, tagging each hit with the attacker for the kill feed.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CreatorTag = require(ServerScriptService:WaitForChild("CreatorTag")) :: (Humanoid, Player, string?) -> ()

local DAMAGE = 25
local HIT_COOLDOWN = 0.5 -- seconds before the same target can be hit again

local tool = script.Parent :: Tool
local handle = tool:WaitForChild("Handle") :: BasePart
local lastHit: { [Humanoid]: number } = {}

handle.Touched:Connect(function(hit: BasePart)
	-- The tool's parent is the character holding it
	local character = tool.Parent
	local attacker = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	if not attacker then
		return
	end
	local victimModel = hit.Parent
	local humanoid = victimModel and victimModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or victimModel == character or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	if now - (lastHit[humanoid] or 0) < HIT_COOLDOWN then
		return
	end
	lastHit[humanoid] = now
	CreatorTag(humanoid, attacker, tool.Name)
	humanoid:TakeDamage(DAMAGE)
end)
