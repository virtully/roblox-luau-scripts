--!strict
-- How to make fall damage in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fall-damage
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FallDamage
-- Script in ServerScriptService named FallDamage.
-- Players lose health when they land after falling further than SAFE_FALL_STUDS.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SAFE_FALL_STUDS = 20 -- falls up to this height do no damage
local DAMAGE_PER_STUD = 2 -- health lost for each stud past the safe height
local MIN_LANDING_SPEED = 60 -- studs per second downwards a landing needs (a normal jump lands at about 53)
local FALLING_SPEED = 8 -- below minus this vertical speed, the character counts as falling
local TELEPORT_STUDS = 30 -- a jump bigger than this in one frame is a teleport, not a fall

type FallState = {
	peakY: number, -- highest point since the character last stood still vertically
	lastY: number,
	lastVelocityY: number,
	falling: boolean,
}

local states: { [Model]: FallState } = {}

local function isInWater(position: Vector3): boolean
	-- Read the terrain voxels around the character; Water there means a soft landing
	local region = Region3.new(position - Vector3.new(4, 6, 4), position + Vector3.new(4, 2, 4)):ExpandToGrid(4)
	local materials = workspace.Terrain:ReadVoxels(region, 4)
	for _, plane in materials do
		for _, row in plane do
			for _, material in row do
				if material == Enum.Material.Water then
					return true
				end
			end
		end
	end
	return false
end

local function onLanded(humanoid: Humanoid, fallen: number, landingSpeed: number, position: Vector3)
	if fallen <= SAFE_FALL_STUDS or landingSpeed < MIN_LANDING_SPEED then
		return
	end
	if humanoid.Sit or isInWater(position) then
		return
	end
	local damage = (fallen - SAFE_FALL_STUDS) * DAMAGE_PER_STUD
	-- TakeDamage does nothing while the character has a ForceField (spawn protection)
	humanoid:TakeDamage(damage)
end

local function update(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if not (humanoid and root) or humanoid.Health <= 0 then
		return
	end
	local y = root.Position.Y
	local velocityY = root.AssemblyLinearVelocity.Y
	local state = states[character]
	if not state or math.abs(y - state.lastY) > TELEPORT_STUDS then
		-- First frame, or the character was teleported: start counting from here
		states[character] = { peakY = y, lastY = y, lastVelocityY = velocityY, falling = false }
		return
	end

	if math.abs(velocityY) < 1 and not state.falling then
		state.peakY = y -- standing, or the top of a jump: a fall would start here
	elseif y > state.peakY then
		state.peakY = y
	end

	if velocityY < -FALLING_SPEED then
		state.falling = true
	elseif state.falling and velocityY > state.lastVelocityY * 0.5 then
		-- The downward speed dropped by more than half in one step: the character hit something
		state.falling = false
		onLanded(humanoid, state.peakY - y, -state.lastVelocityY, root.Position)
		state.peakY = y
	end

	state.lastY = y
	state.lastVelocityY = velocityY
end

RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			update(character)
		end
	end
end)

-- Forget a character when it is removed, so the table does not grow forever
local function onCharacterAdded(character: Model)
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			states[character] = nil
		end
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end
