--!strict
-- How to make a day and night cycle in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-day-night-cycle
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DayNightCycle
-- Script in ServerScriptService named DayNightCycle.
-- Runs a full day in DAY_MINUTES real minutes. Lighting changes reach every player.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local DAY_MINUTES = 10 -- real minutes for one whole day and night
local START_HOUR = 8 -- the time of day when the server starts (0 to 24)

local hoursPerSecond = 24 / (DAY_MINUTES * 60)
Lighting.ClockTime = START_HOUR

RunService.Heartbeat:Connect(function(deltaTime: number)
	Lighting.ClockTime = (Lighting.ClockTime + deltaTime * hoursPerSecond) % 24
end)
