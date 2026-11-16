--!strict
-- How to make a dash in Roblox Studio (Q to dash)
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-dash-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named DashClient
-- LocalScript in StarterPlayerScripts named DashClient.
-- Press Q (B on a gamepad, or the Dash button on a phone) to dash the way you are moving.
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DASH_SPEED = 70 -- studs per second during the dash (walking is 16)
local DASH_SECONDS = 0.18 -- how long the push lasts
local DASH_COOLDOWN = 1.5 -- seconds between dashes
local AIR_DASHES = 1 -- dashes allowed before touching the ground again

local player = Players.LocalPlayer
local lastDash = -math.huge
local airDashesUsed = 0

local function getHumanoid(): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function dash()
	local humanoid = getHumanoid()
	local root = humanoid and humanoid.RootPart
	if not (humanoid and root) or humanoid.Sit then
		return -- no dash while dead or sitting: a seated character would shove its seat
	end
	local now = os.clock()
	if now - lastDash < DASH_COOLDOWN then
		return
	end
	local inAir = humanoid.FloorMaterial == Enum.Material.Air
	if inAir and airDashesUsed >= AIR_DASHES then
		return
	end
	local attachment = root:FindFirstChild("RootAttachment")
	if not (attachment and attachment:IsA("Attachment")) then
		return
	end
	lastDash = now
	if inAir then
		airDashesUsed += 1
	end

	-- Dash the way the player is moving, or the way they face when standing still
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	-- Plane mode holds the speed on the X and Z axes only, so gravity still works
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * DASH_SPEED
	velocity.MaxForce = math.huge
	velocity.Parent = root
	Debris:AddItem(velocity, DASH_SECONDS)

	-- Ask the server for the trail (Step 3). Skipped if DashServer is not in the game.
	local remote = ReplicatedStorage:FindFirstChild("DashEffect")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer()
	end
end

local function onDash(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		dash()
	end
	return Enum.ContextActionResult.Pass
end

-- One call binds the key, a gamepad button and, on touch screens, an on-screen button
ContextActionService:BindAction("Dash", onDash, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("Dash", "Dash")
ContextActionService:SetPosition("Dash", UDim2.new(1, -170, 1, -120))

-- Every frame: refill the air dash on the ground, and show the cooldown on the phone button
RunService.Heartbeat:Connect(function()
	local humanoid = getHumanoid()
	if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
		airDashesUsed = 0
	end
	local left = DASH_COOLDOWN - (os.clock() - lastDash)
	ContextActionService:SetTitle("Dash", if left > 0 then string.format("%.1f", left) else "Dash")
end)

player.CharacterAdded:Connect(function()
	airDashesUsed = 0
end)
