--!strict
-- How to make an XP and level system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-xp-level-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named XpOrbs
-- Script in ServerScriptService named XpOrbs.
-- Parts tagged "XpOrb" give XP on touch, then come back after a while.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local XP_PER_ORB = 25
local RESPAWN_SECONDS = 10

local awardXp = ServerStorage:WaitForChild("AwardXp") :: BindableEvent

local function setUpOrb(orb: Instance)
	if not orb:IsA("BasePart") then
		return
	end
	local ready = true
	orb.Touched:Connect(function(hit: BasePart)
		if not ready then
			return
		end
		local character = hit.Parent
		local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
		if not player then
			return
		end
		ready = false
		orb.Transparency = 1
		orb.CanTouch = false
		awardXp:Fire(player, XP_PER_ORB)
		task.delay(RESPAWN_SECONDS, function()
			orb.Transparency = 0
			orb.CanTouch = true
			ready = true
		end)
	end)
end

for _, orb in CollectionService:GetTagged("XpOrb") do
	setUpOrb(orb)
end
CollectionService:GetInstanceAddedSignal("XpOrb"):Connect(setUpOrb)
