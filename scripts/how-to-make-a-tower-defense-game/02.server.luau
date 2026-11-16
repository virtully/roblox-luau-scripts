--!strict
-- How to make a tower defense game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-tower-defense-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Towers
-- Script in ServerScriptService named Towers.
-- Every part tagged Tower shoots the enemy in range that is furthest along the path.
-- Tower stats are attributes: Range, Damage, Cooldown, OwnerId.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
type Enemy = { part: BasePart, health: number, speed: number, distance: number, reward: number }
type EnemiesModule = { alive: { Enemy }, baseHealth: number, spawn: (number, number, number) -> () }
local Enemies = require(ServerScriptService:WaitForChild("Enemies")) :: EnemiesModule

local lastShot: { [Instance]: number } = {}

local function num(tower: Instance, name: string, default: number): number
	local value = tower:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function payOwner(tower: Instance, amount: number)
	local owner = Players:GetPlayerByUserId(num(tower, "OwnerId", 0))
	local leaderstats = owner and owner:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cash.Value += amount
	end
end

while true do
	task.wait(0.1)
	for _, tower in CollectionService:GetTagged("Tower") do
		if not tower:IsA("BasePart") or os.clock() - (lastShot[tower] or 0) < num(tower, "Cooldown", 1) then
			continue
		end
		local target: Enemy? = nil
		for _, enemy in Enemies.alive do -- "first": the one that walked furthest
			local inRange = (enemy.part.Position - tower.Position).Magnitude <= num(tower, "Range", 20)
			if inRange and enemy.health > 0 and (not target or enemy.distance > target.distance) then
				target = enemy
			end
		end
		if target then
			lastShot[tower] = os.clock()
			target.health -= num(tower, "Damage", 5)
			if target.health <= 0 then
				payOwner(tower, target.reward)
			end
		end
	end
end
