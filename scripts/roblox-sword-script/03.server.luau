--!strict
-- How to make a sword in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sword-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SwordService
-- Script in ServerScriptService named SwordService (the wind-up and wall check version).
-- Replaces the Step 2 script: same settings and remote, plus two rules. The hit lands
-- WINDUP_SECONDS after the click, when the swing reaches the target, and nobody is hit
-- through a wall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings
local SWORD_NAME = "Sword"
local DAMAGE = 20
local COOLDOWN_SECONDS = 0.6 -- keep the same value in SwordClient
local WINDUP_SECONDS = 0.15 -- time from the click to the hit; match it to your swing animation
local HIT_RANGE = 6
local HIT_WIDTH = 5
local HIT_HEIGHT = 6
local FRIENDLY_FIRE = false
local NETWORK_SLACK = 0.1

local swingEvent = Instance.new("RemoteEvent")
swingEvent.Name = "SwordSwing"
swingEvent.Parent = ReplicatedStorage

local lastSwing: { [Player]: number } = {}

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

-- Returns the attacker's character and root part while they are alive and holding the sword
local function getArmedCharacter(player: Player): (Model?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not (character and humanoid and rootPart) or humanoid.Health <= 0 then
		return nil, nil
	end
	local sword = character:FindFirstChild(SWORD_NAME)
	if not (sword and sword:IsA("Tool")) then
		return nil, nil
	end
	return character, rootPart
end

-- True when nothing but the target stands between the attacker and the target
local function hasClearLine(attacker: Model, from: BasePart, target: Model, to: BasePart): boolean
	local params = RaycastParams.new()
	params.ExcludeInstances = { attacker }
	local result = workspace:Raycast(from.Position, to.Position - from.Position, params)
	return result == nil or result.Instance:IsDescendantOf(target)
end

local function strike(player: Player)
	-- Checked again after the wind-up: the attacker may have died or put the sword away
	local character, rootPart = getArmedCharacter(player)
	if not (character and rootPart) then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local boxCFrame = rootPart.CFrame * CFrame.new(0, 0, -HIT_RANGE / 2)
	local parts = workspace:GetPartBoundsInBox(boxCFrame, Vector3.new(HIT_WIDTH, HIT_HEIGHT, HIT_RANGE), params)

	local alreadyHit: { [Humanoid]: boolean } = {}
	for _, part in parts do
		local model = part:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		local targetRoot = target and target.RootPart
		if model and target and targetRoot and not alreadyHit[target] and target.Health > 0 then
			alreadyHit[target] = true
			if not isTeammate(player, Players:GetPlayerFromCharacter(model)) and hasClearLine(character, rootPart, model, targetRoot) then
				target:TakeDamage(DAMAGE)
			end
		end
	end
end

swingEvent.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	local last = lastSwing[player]
	if last and now - last < COOLDOWN_SECONDS - NETWORK_SLACK then
		return
	end
	local character = getArmedCharacter(player)
	if not character then
		return
	end
	lastSwing[player] = now
	task.delay(WINDUP_SECONDS, strike, player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastSwing[player] = nil
end)
