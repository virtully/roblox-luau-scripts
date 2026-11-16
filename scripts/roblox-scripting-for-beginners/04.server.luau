--!strict
-- How to script in Roblox Studio: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-scripting-for-beginners
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Pad part in Workspace named TouchPad
-- Script inside a Part in Workspace named Pad, script named TouchPad.
-- Events: when a player steps on the pad, it glows yellow and Output says who it was.
-- A debounce stops it running many times a second while they stand on it.

local Players = game:GetService("Players")

local pad = script.Parent :: BasePart
local COOLDOWN_SECONDS = 2

local normalColour = pad.Color
local busy = false

local function onTouched(otherPart: BasePart)
	if busy then
		return -- still cooling down from the last touch
	end
	-- The character is the Model that holds the body part (or hat) that touched the pad
	local character = otherPart:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return -- a loose part or an NPC touched it, not a player
	end

	busy = true
	print(`{player.Name} stepped on the pad`)
	pad.Color = Color3.fromRGB(255, 220, 0)
	task.wait(COOLDOWN_SECONDS)
	pad.Color = normalColour
	busy = false
end

pad.Touched:Connect(onTouched)
