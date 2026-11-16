--!strict
-- Roblox shift to sprint script for PC, mobile and console
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sprint-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named DoubleJump
-- Gives one extra jump in the air. It runs again for every new character,
-- so nothing carries over after a respawn.

local UserInputService = game:GetService("UserInputService")

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local EXTRA_JUMPS = 1
local MIN_SECONDS_BETWEEN_JUMPS = 0.25 -- JumpRequest fires several times for one press
local NEW_PRESS_GAP = 0.1 -- a held jump button keeps firing JumpRequest; a pause this long means it was let go

local jumpsLeft = 0
local lastJump = 0
local lastRequest = 0

humanoid.StateChanged:Connect(function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
	if newState == Enum.HumanoidStateType.Jumping and oldState ~= Enum.HumanoidStateType.Freefall then
		-- A jump from the ground (not one of our air jumps) refills the air jumps
		jumpsLeft = EXTRA_JUMPS
		lastJump = os.clock()
	elseif newState == Enum.HumanoidStateType.Landed then
		jumpsLeft = 0
	end
end)

-- JumpRequest fires whenever the player asks to jump, such as with Space or the phone's jump button
UserInputService.JumpRequest:Connect(function()
	local now = os.clock()
	local newPress = now - lastRequest > NEW_PRESS_GAP
	lastRequest = now
	-- Only a fresh press jumps again, so holding the button does not use up the air jump
	if not newPress or jumpsLeft <= 0 or now - lastJump < MIN_SECONDS_BETWEEN_JUMPS then
		return
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		jumpsLeft -= 1
		lastJump = now
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
