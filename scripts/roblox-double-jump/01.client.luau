--!strict
-- How to make a double jump in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-double-jump
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named DoubleJump
-- LocalScript in StarterCharacterScripts named DoubleJump.
-- Press jump in the air to jump again. Air jumps refill when you land.
-- Roblox copies this script into every new character, so each life starts fresh.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local DEFAULT_AIR_JUMPS = 1 -- used until the server sets the AirJumps attribute
local MIN_SECONDS_BETWEEN_JUMPS = 0.25 -- JumpRequest fires several times for one press
local NEW_PRESS_GAP = 0.1 -- a held button keeps requesting jumps; a pause this long means a new press

local player = Players.LocalPlayer
local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local jumpsLeft = 0
local lastJump = 0
local lastRequest = 0

-- The server can change the number of air jumps with a player attribute (Step 3)
local function getAirJumps(): number
	local value = player:GetAttribute("AirJumps")
	if typeof(value) == "number" then
		return math.clamp(math.floor(value), 0, 10)
	end
	return DEFAULT_AIR_JUMPS
end

-- States where the character is not in the air: air jumps are taken away
local GROUNDED: { [Enum.HumanoidStateType]: boolean } = {
	[Enum.HumanoidStateType.Landed] = true,
	[Enum.HumanoidStateType.Running] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Dead] = true,
}

humanoid.StateChanged:Connect(function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
	if newState == Enum.HumanoidStateType.Jumping and oldState ~= Enum.HumanoidStateType.Freefall then
		-- A jump from the ground (not one of our air jumps) hands out the air jumps
		jumpsLeft = getAirJumps()
		lastJump = os.clock()
	elseif newState == Enum.HumanoidStateType.Freefall and oldState ~= Enum.HumanoidStateType.Jumping then
		-- Walked off a ledge without jumping: allow the air jumps here too.
		-- Delete these two lines if a fall should not give a jump.
		jumpsLeft = getAirJumps()
	elseif GROUNDED[newState] then
		jumpsLeft = 0
	end
end)

local function airJump()
	jumpsLeft -= 1
	lastJump = os.clock()
	-- Roblox pushes the character up with its normal jump strength and plays the jump animation
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

-- JumpRequest fires for Space, the phone jump button and the gamepad A button
UserInputService.JumpRequest:Connect(function()
	local now = os.clock()
	local newPress = now - lastRequest > NEW_PRESS_GAP
	lastRequest = now
	if not newPress or jumpsLeft <= 0 or now - lastJump < MIN_SECONDS_BETWEEN_JUMPS then
		return
	end
	if humanoid.Health <= 0 or humanoid.FloorMaterial ~= Enum.Material.Air then
		return -- dead, or still on the ground: Roblox handles a normal jump itself
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		airJump()
	end
end)
