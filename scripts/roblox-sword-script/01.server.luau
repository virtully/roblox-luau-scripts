--!strict
-- How to make a sword in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sword-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SwordService
-- Script in ServerScriptService named SwordService.
-- The only place a sword hit can happen: it checks the swing, finds targets in front
-- of the attacker with its own hitbox, and deals the damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings
local SWORD_NAME = "Sword" -- the Tool's name in StarterPack
local DAMAGE = 20
local COOLDOWN_SECONDS = 0.6 -- keep the same value in SwordClient
local HIT_RANGE = 6 -- studs in front of the attacker
local HIT_WIDTH = 5
local HIT_HEIGHT = 6
local FRIENDLY_FIRE = false -- false: players on the same team cannot hurt each other
-- Swings sent exactly COOLDOWN_SECONDS apart can arrive a little closer together after a
-- network delay, so the server allows this much slack instead of dropping a real swing
local NETWORK_SLACK = 0.1

-- The remote the sword's LocalScript fires. It carries no arguments: the server
-- decides who is hit, so there is nothing for a client to fake.
local swingEvent = Instance.new("RemoteEvent")
swingEvent.Name = "SwordSwing"
swingEvent.Parent = ReplicatedStorage

local lastSwing: { [Player]: number } = {}

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	-- Neutral players (no team) can always hit each other
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

local function onSwing(player: Player)
	-- 1. One swing per cooldown, however often the remote is fired
	local now = os.clock()
	local last = lastSwing[player]
	if last and now - last < COOLDOWN_SECONDS - NETWORK_SLACK then
		return
	end

	-- 2. The attacker must be alive and holding the sword
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not (character and humanoid and rootPart) or humanoid.Health <= 0 then
		return
	end
	local sword = character:FindFirstChild(SWORD_NAME)
	if not (sword and sword:IsA("Tool")) then
		return
	end
	lastSwing[player] = now

	-- 3. The server's own hitbox: a box in front of the attacker's root part
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local boxCFrame = rootPart.CFrame * CFrame.new(0, 0, -HIT_RANGE / 2)
	local parts = workspace:GetPartBoundsInBox(boxCFrame, Vector3.new(HIT_WIDTH, HIT_HEIGHT, HIT_RANGE), params)

	-- 4. Damage each Humanoid in the box once, even if several of its parts are inside
	local alreadyHit: { [Humanoid]: boolean } = {}
	for _, part in parts do
		local model = part:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		if model and target and not alreadyHit[target] and target.Health > 0 then
			alreadyHit[target] = true
			if not isTeammate(player, Players:GetPlayerFromCharacter(model)) then
				target:TakeDamage(DAMAGE) -- does nothing while the target has a ForceField
			end
		end
	end
end

swingEvent.OnServerEvent:Connect(onSwing)

Players.PlayerRemoving:Connect(function(player: Player)
	lastSwing[player] = nil
end)
