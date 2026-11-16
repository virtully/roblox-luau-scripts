--!strict
-- How to make an RPG game in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-rpg-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Progression
-- ModuleScript in ServerScriptService named Progression.
-- Damage credit, XP split by damage dealt, and level ups on a curve. Only server scripts require it.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Progression = {}

local MAX_LEVEL = 50
local damageBy: { [Humanoid]: { [Player]: number } } = {}

-- XP needed to go from this level to the next: grows faster than linear, so levels slow down
function Progression.xpToNext(level: number): number
	return math.floor(100 * level ^ 1.5)
end

function Progression.giveXP(player: Player, amount: number)
	local level = tonumber(player:GetAttribute("Level")) or 1
	local xp = (tonumber(player:GetAttribute("XP")) or 0) + amount
	while level < MAX_LEVEL and xp >= Progression.xpToNext(level) do
		xp -= Progression.xpToNext(level)
		level += 1
	end
	player:SetAttribute("Level", level)
	player:SetAttribute("XP", xp)
end

-- Your weapon and spell scripts call this instead of Humanoid:TakeDamage
function Progression.damage(player: Player, enemy: Humanoid, amount: number)
	if enemy.Health <= 0 then
		return
	end
	local dealt = math.min(amount, enemy.Health)
	local byPlayer: { [Player]: number } = damageBy[enemy] or {}
	byPlayer[player] = (byPlayer[player] or 0) + dealt
	damageBy[enemy] = byPlayer
	enemy:TakeDamage(amount)
end

-- Enemies: a Humanoid tagged "Enemy" with an XP attribute. Everyone who hit it gets a share.
local function watch(enemy: Instance)
	if not enemy:IsA("Humanoid") then
		return
	end
	enemy.Died:Connect(function()
		local byPlayer: { [Player]: number } = damageBy[enemy] or {}
		damageBy[enemy] = nil
		local reward = tonumber(enemy:GetAttribute("XP")) or 10
		for player, dealt in byPlayer do
			if player.Parent == Players then
				Progression.giveXP(player, math.ceil(reward * dealt / enemy.MaxHealth))
			end
		end
	end)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(watch)
for _, enemy in CollectionService:GetTagged("Enemy") do
	watch(enemy)
end

return Progression
