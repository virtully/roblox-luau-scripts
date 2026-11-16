--!strict
-- How to make a ragdoll on death in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-ragdoll-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RagdollOnDeath
-- Script in ServerScriptService named RagdollOnDeath.
-- When a player's character dies, its joints become ball sockets, so it falls limp in one piece.
local Players = game:GetService("Players")

local DEFAULT_ANGLE = 45 -- degrees a joint can bend when it has no entry below
local SERVER_OWNS_BODY = true -- the server simulates the body, so everyone sees the same fall

-- Limits per joint, found by a word in the motor's name (R15 "LeftShoulder", R6 "Left Shoulder")
type Limit = { angle: number, twist: number }
local JOINT_LIMITS: { [string]: Limit } = {
	neck = { angle = 30, twist = 40 },
	waist = { angle = 30, twist = 20 },
	shoulder = { angle = 90, twist = 45 },
	elbow = { angle = 60, twist = 5 },
	wrist = { angle = 30, twist = 10 },
	hip = { angle = 60, twist = 20 },
	knee = { angle = 60, twist = 5 },
	ankle = { angle = 30, twist = 10 },
}

local function getLimit(motorName: string): Limit
	local name = string.lower(motorName)
	for word, limit in JOINT_LIMITS do
		if string.find(name, word, 1, true) then
			return limit
		end
	end
	return { angle = DEFAULT_ANGLE, twist = DEFAULT_ANGLE }
end

local function ragdoll(character: Model, humanoid: Humanoid)
	local root = humanoid.RootPart
	for _, motor in character:GetDescendants() do
		if not motor:IsA("Motor6D") then
			continue
		end
		local part0, part1 = motor.Part0, motor.Part1
		-- Keep the root joint: it holds the invisible HumanoidRootPart to the body
		if not (part0 and part1) or part0 == root or part1 == root then
			continue
		end
		local a0 = Instance.new("Attachment")
		a0.Name = "RagdollAttachment0"
		a0.CFrame = motor.C0 -- the joint point, in Part0's space
		a0.Parent = part0
		local a1 = Instance.new("Attachment")
		a1.Name = "RagdollAttachment1"
		a1.CFrame = motor.C1 -- the same point, in Part1's space
		a1.Parent = part1

		local limit = getLimit(motor.Name)
		local socket = Instance.new("BallSocketConstraint")
		socket.Attachment0 = a0
		socket.Attachment1 = a1
		socket.LimitsEnabled = true
		socket.UpperAngle = limit.angle
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = -limit.twist
		socket.TwistUpperAngle = limit.twist
		socket.Parent = part1

		motor.Enabled = false -- the ball socket holds the parts now
	end

	-- Limbs collide with the floor so they do not sink into it; the root part does not
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Parent == character then
			part.CanCollide = part ~= root
		end
	end

	if SERVER_OWNS_BODY and root and not root.Anchored then
		-- pcall: ownership of anchored parts cannot be changed, so never let this stop the script
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	-- Without this, Roblox breaks every joint the moment the character dies
	humanoid.BreakJointsOnDeath = false
	humanoid.Died:Once(function()
		ragdoll(character, humanoid)
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
