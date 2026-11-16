--!strict
-- Roblox NPC pathfinding: make an NPC follow and chase players
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-pathfinding
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Chaser model named TouchDamage
local Players = game:GetService("Players")

local npc = script.Parent :: Model
local humanoid = npc:WaitForChild("Humanoid") :: Humanoid

local DAMAGE = 10
local COOLDOWN_SECONDS = 1

local lastHit: { [Player]: number } = {}

local function onTouched(hit: BasePart)
	if humanoid.Health <= 0 then
		return -- a defeated NPC does no damage
	end
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not player or not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	local last = lastHit[player]
	if last and now - last < COOLDOWN_SECONDS then
		return -- Touched fires many times per second while parts overlap
	end
	lastHit[player] = now

	targetHumanoid:TakeDamage(DAMAGE)
end

for _, descendant in npc:GetDescendants() do
	if descendant:IsA("BasePart") then
		descendant.Touched:Connect(onTouched)
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastHit[player] = nil
end)
