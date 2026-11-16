--!strict
-- How to add a music player to your Roblox game
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-music-player
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the part named TouchSound
-- Script inside a part, named TouchSound. Put a Sound inside the same part.
-- Plays the sound when a player touches the part. Everyone nearby hears it.
local Players = game:GetService("Players")

local COOLDOWN = 1 -- seconds before the sound can play again

local part = script.Parent :: BasePart
local sound = part:FindFirstChildOfClass("Sound")
local lastPlayed = -math.huge

part.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	if not (sound and character and character:IsA("Model") and Players:GetPlayerFromCharacter(character)) then
		return
	end
	local now = os.clock()
	if now - lastPlayed < COOLDOWN then
		return
	end
	lastPlayed = now
	-- A Sound inside a part plays from that spot: louder close by, quieter far away
	sound:Play()
end)
