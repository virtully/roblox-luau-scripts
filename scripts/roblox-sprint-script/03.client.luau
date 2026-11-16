--!strict
-- Roblox shift to sprint script for PC, mobile and console
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sprint-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MovementClient
-- Hold Shift (or L3, or the Sprint button on a phone) to sprint while stamina lasts.
-- Press Q (or B, or the Dash button) to dash in the direction you are moving.

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

type Config = {
	SPRINT_BONUS: number,
	MAX_STAMINA: number,
	DRAIN_PER_SECOND: number,
	REGEN_PER_SECOND: number,
	REGEN_DELAY: number,
	MIN_TO_START: number,
	DASH_SPEED: number,
	DASH_SECONDS: number,
	DASH_COST: number,
	DASH_COOLDOWN: number,
}
local Config = require(ReplicatedStorage:WaitForChild("MovementConfig")) :: Config

local player = Players.LocalPlayer
local stamina = Config.MAX_STAMINA
local sprintHeld = false
local sprinting = false
local normalSpeed = 16 -- the WalkSpeed to go back to when sprinting stops
local lastSprintTime = 0
local lastDashTime = -math.huge

-- Stamina bar: a frame with a fill whose width is the stamina left
local gui = Instance.new("ScreenGui")
gui.Name = "StaminaGui"
gui.ResetOnSpawn = false
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -24)
bar.Size = UDim2.fromOffset(240, 14)
bar.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
bar.Parent = gui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(80, 220, 150)
fill.BorderSizePixel = 0
fill.Parent = bar
for _, frame in { bar, fill } do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
end
gui.Parent = player:WaitForChild("PlayerGui")

local function getHumanoid(): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- Sprint: only a flag here; the Heartbeat loop below decides every frame whether to sprint
local function onSprint(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	-- Only a press or a release changes it: a finger sliding on the touch button sends Change
	if state == Enum.UserInputState.Begin then
		sprintHeld = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		sprintHeld = false
	end
	return Enum.ContextActionResult.Pass
end

local function dash()
	local humanoid = getHumanoid()
	local rootPart = humanoid and humanoid.RootPart
	local now = os.clock()
	-- No dash while sitting: a seated character is welded to its seat, so it would push the whole vehicle
	if not (humanoid and rootPart) or humanoid.Sit or now - lastDashTime < Config.DASH_COOLDOWN or stamina < Config.DASH_COST then
		return
	end
	local attachment = rootPart:FindFirstChild("RootAttachment")
	if not (attachment and attachment:IsA("Attachment")) then
		return
	end
	lastDashTime = now
	stamina -= Config.DASH_COST
	lastSprintTime = now -- pause the refill, as sprinting does

	-- Dash the way the player is moving, or the way they face if they are standing still
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = rootPart.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	-- LinearVelocity in Plane mode holds the horizontal speed and leaves gravity alone
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * Config.DASH_SPEED
	velocity.MaxForce = math.huge
	velocity.Parent = rootPart
	Debris:AddItem(velocity, Config.DASH_SECONDS)
end

local function onDash(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		dash()
	end
	return Enum.ContextActionResult.Pass
end

-- One call each binds a key, a gamepad button and, on touch devices, an on-screen button
ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:BindAction("Dash", onDash, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("Sprint", "Sprint")
ContextActionService:SetTitle("Dash", "Dash")

-- Every frame: drain stamina while sprinting and moving, refill it after a short rest
RunService.Heartbeat:Connect(function(deltaTime: number)
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	local moving = humanoid.MoveDirection.Magnitude > 0
	local now = os.clock()
	local enoughStamina = if sprinting then stamina > 0 else stamina >= Config.MIN_TO_START
	local shouldSprint = sprintHeld and moving and enoughStamina

	-- Change WalkSpeed only when sprinting starts or stops, so a speed set by
	-- another script (such as a speed pass) is kept and sprinting adds to it
	if shouldSprint and not sprinting then
		sprinting = true
		normalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = normalSpeed + Config.SPRINT_BONUS
	elseif not shouldSprint and sprinting then
		sprinting = false
		humanoid.WalkSpeed = normalSpeed
	end

	if sprinting then
		stamina = math.max(0, stamina - Config.DRAIN_PER_SECOND * deltaTime)
		lastSprintTime = now
	elseif now - lastSprintTime >= Config.REGEN_DELAY then
		stamina = math.min(Config.MAX_STAMINA, stamina + Config.REGEN_PER_SECOND * deltaTime)
	end
	fill.Size = UDim2.fromScale(stamina / Config.MAX_STAMINA, 1)
end)

-- A new character starts with full stamina and nothing held
player.CharacterAdded:Connect(function()
	stamina = Config.MAX_STAMINA
	sprintHeld = false
	sprinting = false -- the new Humanoid starts at its normal WalkSpeed
end)
