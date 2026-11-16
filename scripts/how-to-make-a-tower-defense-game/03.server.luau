--!strict
-- How to make a tower defense game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-tower-defense-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Waves
-- Script in ServerScriptService named Waves.
-- Sends each wave, waits until it is cleared, then gives players time to build.
local ServerScriptService = game:GetService("ServerScriptService")
type EnemiesModule = { alive: { any }, baseHealth: number, spawn: (number, number, number) -> () }
local Enemies = require(ServerScriptService:WaitForChild("Enemies")) :: EnemiesModule

local WAVES = { -- count, health, speed (studs per second), cash per kill
	{ count = 8, health = 10, speed = 6, reward = 5 },
	{ count = 12, health = 18, speed = 7, reward = 6 },
	{ count = 6, health = 80, speed = 4, reward = 25 }, -- a slow, tough wave
}

for wave, info in WAVES do
	workspace:SetAttribute("Wave", wave)
	for _ = 1, info.count do
		Enemies.spawn(info.health, info.speed, info.reward)
		task.wait(1)
	end
	repeat
		task.wait(0.5)
	until #Enemies.alive == 0 or Enemies.baseHealth <= 0
	if Enemies.baseHealth <= 0 then
		break
	end
	task.wait(5) -- build time between waves
end
