--!strict
-- How to make fall damage in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fall-damage
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the FallDamage Script named SpeedDamage
-- Replacement for onLanded in the FallDamage Script: damage grows with the landing speed.
local SAFE_LANDING_SPEED = 90 -- studs per second; about a 20 stud fall at default gravity
local DAMAGE_PER_SPEED = 1 -- health per stud per second above the safe speed

local function isInWater(_position: Vector3): boolean
	return false -- use the isInWater function from Step 1
end

local function onLanded(humanoid: Humanoid, _fallen: number, landingSpeed: number, position: Vector3)
	if landingSpeed <= SAFE_LANDING_SPEED or humanoid.Sit or isInWater(position) then
		return
	end
	humanoid:TakeDamage((landingSpeed - SAFE_LANDING_SPEED) * DAMAGE_PER_SPEED)
end

return onLanded
