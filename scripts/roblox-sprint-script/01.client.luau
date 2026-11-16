--!strict
-- Roblox shift to sprint script for PC, mobile and console
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sprint-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ShiftToSprint
-- LocalScript in StarterPlayer > StarterPlayerScripts, named ShiftToSprint.
-- Hold Left Shift to sprint. On a gamepad, click the left stick (L3) to switch
-- sprinting on and off. On a phone, tap the Sprint button to switch it on and off.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

-- Settings
local SPRINT_BONUS = 10 -- added to WalkSpeed while sprinting (16 becomes 26)
local TOGGLE_ON_TOUCH_AND_GAMEPAD = true -- false: hold the button instead

local player = Players.LocalPlayer
local sprinting = false
local normalSpeed = 16 -- the WalkSpeed to go back to

local function getHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function setSprinting(on: boolean)
	local humanoid = getHumanoid()
	if not humanoid or on == sprinting then
		return
	end
	sprinting = on
	if on then
		-- Remember the current speed and add to it, so a speed boost from elsewhere is kept
		normalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = normalSpeed + SPRINT_BONUS
	else
		humanoid.WalkSpeed = normalSpeed
	end
end

local function onSprint(_name: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local isKeyboard = input.UserInputType == Enum.UserInputType.Keyboard
	if isKeyboard or not TOGGLE_ON_TOUCH_AND_GAMEPAD then
		-- Hold: sprint while the key or button is down
		if state == Enum.UserInputState.Begin then
			setSprinting(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setSprinting(false)
		end
	elseif state == Enum.UserInputState.Begin then
		-- Toggle: each press switches sprinting on or off
		setSprinting(not sprinting)
	end
	return Enum.ContextActionResult.Pass
end

-- One call binds the key, the gamepad button and, on touch screens, an on-screen button
ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "Sprint")

-- A new character starts walking: its Humanoid already has the normal WalkSpeed
player.CharacterAdded:Connect(function()
	sprinting = false
end)
