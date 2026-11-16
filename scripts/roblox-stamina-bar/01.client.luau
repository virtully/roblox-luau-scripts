--!strict
-- How to make a stamina bar in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-stamina-bar
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named StaminaSprint
-- LocalScript in StarterPlayerScripts named StaminaSprint.
-- Hold Shift (L3 on a gamepad, or the Sprint button on a phone) to sprint while stamina lasts.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_STAMINA = 100
local SPRINT_BONUS = 10 -- added to WalkSpeed while sprinting (16 becomes 26)
local DRAIN_PER_SECOND = 20 -- a full bar lasts MAX_STAMINA / DRAIN_PER_SECOND seconds
local REGEN_PER_SECOND = 15
local REGEN_DELAY = 1 -- seconds of rest before stamina refills
local MIN_TO_SPRINT = 30 -- after running dry, stamina needed to sprint again
local JUMP_COST = 0 -- stamina per jump, 0 for free jumps

local player = Players.LocalPlayer
local stamina = MAX_STAMINA
local sprintHeld = false
local sprinting = false
local tired = false -- true after the bar hits 0, until it is back to MIN_TO_SPRINT
local normalSpeed = 16
local lastUse = 0
local jumpAllowed = true

-- The bar: a dark frame with a coloured fill and a number on top
local gui = Instance.new("ScreenGui")
gui.Name = "StaminaGui"
gui.ResetOnSpawn = false -- keep the bar through respawns
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -28)
bar.Size = UDim2.fromOffset(260, 16)
bar.BackgroundColor3 = Color3.fromRGB(24, 22, 32)
bar.Parent = gui
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.7
stroke.Thickness = 1.5
stroke.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BorderSizePixel = 0
fill.Parent = bar
for _, frame in { bar, fill } do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
end
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 12
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0.6
label.ZIndex = 2
label.Parent = bar
gui.Parent = player:WaitForChild("PlayerGui")

local FULL_COLOR = Color3.fromRGB(80, 220, 140)
local LOW_COLOR = Color3.fromRGB(240, 70, 70)
local TIRED_COLOR = Color3.fromRGB(120, 120, 130)

local function getHumanoid(): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function drawBar()
	local share = stamina / MAX_STAMINA
	fill.Size = UDim2.fromScale(share, 1)
	-- Green when full, red when empty, grey while tired
	fill.BackgroundColor3 = if tired then TIRED_COLOR else LOW_COLOR:Lerp(FULL_COLOR, share)
	label.Text = tostring(math.floor(stamina))
end

local function onSprint(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		sprintHeld = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		sprintHeld = false
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("StaminaSprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("StaminaSprint", "Sprint")

RunService.Heartbeat:Connect(function(deltaTime: number)
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	local now = os.clock()
	local moving = humanoid.MoveDirection.Magnitude > 0
	local shouldSprint = sprintHeld and moving and not tired and stamina > 0

	-- Change WalkSpeed only when sprinting starts or stops, so speed from other scripts is kept
	if shouldSprint and not sprinting then
		sprinting = true
		normalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = normalSpeed + SPRINT_BONUS
	elseif not shouldSprint and sprinting then
		sprinting = false
		humanoid.WalkSpeed = normalSpeed
	end

	if sprinting then
		stamina = math.max(0, stamina - DRAIN_PER_SECOND * deltaTime)
		lastUse = now
		if stamina == 0 then
			tired = true
		end
	elseif now - lastUse >= REGEN_DELAY then
		stamina = math.min(MAX_STAMINA, stamina + REGEN_PER_SECOND * deltaTime)
	end
	if tired and stamina >= MIN_TO_SPRINT then
		tired = false
	end

	-- Jumping: allowed only with enough stamina (SetStateEnabled works on this device only)
	if JUMP_COST > 0 then
		local canJump = stamina >= JUMP_COST
		if canJump ~= jumpAllowed then
			jumpAllowed = canJump
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, canJump)
		end
	end

	player:SetAttribute("Stamina", stamina)
	drawBar()
end)

-- Each new character: full bar, jumping allowed, and jumps cost stamina
local function onCharacter(character: Model)
	stamina = MAX_STAMINA
	sprintHeld = false
	sprinting = false
	tired = false
	jumpAllowed = true
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Jumping and JUMP_COST > 0 then
			stamina = math.max(0, stamina - JUMP_COST)
			lastUse = os.clock()
		end
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

drawBar()
