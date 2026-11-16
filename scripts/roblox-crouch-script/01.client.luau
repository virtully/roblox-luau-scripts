--!strict
-- How to make a crouch script in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-crouch-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named Crouch
-- LocalScript in StarterCharacterScripts named Crouch.
-- Hold C (R3 on a gamepad) to crouch. On a phone, the Crouch button switches it on and off.
-- You stay crouched while something is above your head.
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local HIP_DROP = 1.2 -- studs the body drops (R15 only)
local SPEED_MULTIPLIER = 0.5 -- crouched speed as a share of normal speed
local CROUCH_ANIMATION_ID = "" -- for example "rbxassetid://1234567890", or empty for none

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local head = character:WaitForChild("Head") :: BasePart
local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

local wantsCrouch = false -- the button is held (or toggled on, on a phone)
local crouching = false
local normalHipHeight = humanoid.HipHeight
local normalSpeed = humanoid.WalkSpeed
local headTop = 0 -- how far the top of the head is above the root part when standing

local track: AnimationTrack? = nil
if CROUCH_ANIMATION_ID ~= "" then
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local animation = Instance.new("Animation")
	animation.AnimationId = CROUCH_ANIMATION_ID
	local loaded = animator:LoadAnimation(animation)
	loaded.Looped = true
	loaded.Priority = Enum.AnimationPriority.Action
	track = loaded
end

-- The cast ignores the player's own body
local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.FilterDescendantsInstances = { character }

-- True when there is room above the head to stand up
local function hasRoomToStand(): boolean
	local needed = headTop + (if isR15 then HIP_DROP else 0)
	local size = Vector3.new(root.Size.X, 0.2, root.Size.Z)
	local start = CFrame.new(root.Position) -- flat box, no tilt
	local hit = workspace:Blockcast(start, size, Vector3.new(0, needed, 0), castParams)
	return hit == nil
end

local function startCrouch()
	crouching = true
	normalHipHeight = humanoid.HipHeight
	normalSpeed = humanoid.WalkSpeed
	headTop = (head.Position.Y + head.Size.Y / 2) - root.Position.Y
	if isR15 then
		humanoid.HipHeight = math.max(0, normalHipHeight - HIP_DROP)
	end
	humanoid.WalkSpeed = normalSpeed * SPEED_MULTIPLIER
	humanoid.CameraOffset = Vector3.new(0, -HIP_DROP, 0)
	if track then
		track:Play(0.15)
	end
	character:SetAttribute("Crouching", true)
end

local function stopCrouch()
	crouching = false
	if isR15 then
		humanoid.HipHeight = normalHipHeight
	end
	humanoid.WalkSpeed = normalSpeed
	humanoid.CameraOffset = Vector3.zero
	if track then
		track:Stop(0.15)
	end
	character:SetAttribute("Crouching", false)
end

local function onCrouch(_name: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if input.UserInputType == Enum.UserInputType.Touch then
		-- Holding a button on a phone is awkward, so a tap switches crouching on and off
		if state == Enum.UserInputState.Begin then
			wantsCrouch = not wantsCrouch
		end
	elseif state == Enum.UserInputState.Begin then
		wantsCrouch = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		wantsCrouch = false
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Crouch", onCrouch, true, Enum.KeyCode.C, Enum.KeyCode.ButtonR3)
ContextActionService:SetTitle("Crouch", "Crouch")

-- Every frame: crouch or stand to match the button, but only stand when there is room
local heartbeat = RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 then
		return
	end
	if wantsCrouch and not crouching then
		startCrouch()
	elseif not wantsCrouch and crouching and hasRoomToStand() then
		stopCrouch()
	end
	-- Freeze the crouch walk while standing still, so it looks like a crouched idle
	if track and crouching then
		track:AdjustSpeed(if humanoid.MoveDirection.Magnitude > 0 then 1 else 0)
	end
end)

-- This script is removed with the character, so clean up the binding and the loop
humanoid.Died:Connect(function()
	heartbeat:Disconnect()
	ContextActionService:UnbindAction("Crouch")
end)
