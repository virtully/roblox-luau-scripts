--!strict
-- How to make a kill brick (lava) in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-brick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named KillBricks
-- Script in ServerScriptService named KillBricks.
-- Tag parts "KillBrick" to kill on touch, or "DamageBrick" to hurt a little at a time.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DAMAGE_PER_HIT = 20 -- health a DamageBrick takes each time
local DAMAGE_COOLDOWN = 0.5 -- seconds between hits from damage bricks for one player

local lastHit: { [Player]: number } = {}

local function getHumanoid(hit: BasePart): Humanoid?
	local character = hit.Parent
	-- Only player characters, not NPCs or loose parts
	if not (character and character:IsA("Model") and Players:GetPlayerFromCharacter(character)) then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function setUpKillBrick(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit: BasePart)
		local humanoid = getHumanoid(hit)
		if humanoid then
			-- Setting Health to 0 ignores a ForceField, so spawn protection does not save anyone
			humanoid.Health = 0
		end
	end)
end

local function setUpDamageBrick(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit: BasePart)
		local humanoid = getHumanoid(hit)
		local character = humanoid and humanoid.Parent
		local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
		if not (humanoid and player) then
			return
		end
		local now = os.clock()
		if now - (lastHit[player] or 0) < DAMAGE_COOLDOWN then
			return
		end
		lastHit[player] = now
		-- TakeDamage does nothing while the character has a ForceField
		humanoid:TakeDamage(DAMAGE_PER_HIT)
	end)
end

for _, part in CollectionService:GetTagged("KillBrick") do
	setUpKillBrick(part)
end
CollectionService:GetInstanceAddedSignal("KillBrick"):Connect(setUpKillBrick)

for _, part in CollectionService:GetTagged("DamageBrick") do
	setUpDamageBrick(part)
end
CollectionService:GetInstanceAddedSignal("DamageBrick"):Connect(setUpDamageBrick)

Players.PlayerRemoving:Connect(function(player: Player)
	lastHit[player] = nil
end)
