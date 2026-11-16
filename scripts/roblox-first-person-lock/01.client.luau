--!strict
-- How to force first person in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-first-person-lock
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CameraToggle
-- LocalScript in StarterPlayerScripts named CameraToggle.
-- Press V (or the View button on a phone) to switch between first and third person.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local START_IN_FIRST_PERSON = true
local THIRD_PERSON_DISTANCE = 12 -- studs the camera zooms out to for third person

local player = Players.LocalPlayer
local normalMinZoom = player.CameraMinZoomDistance
local firstPerson = false

local function setFirstPerson(on: boolean)
	firstPerson = on
	if on then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
		-- Leaving first person keeps the camera zoomed in. Raising the minimum zoom
		-- for a moment pushes it out, then the player can zoom freely again.
		player.CameraMinZoomDistance = math.min(THIRD_PERSON_DISTANCE, player.CameraMaxZoomDistance)
		task.delay(0.1, function()
			if not firstPerson then
				player.CameraMinZoomDistance = normalMinZoom
			end
		end)
	end
	ContextActionService:SetTitle("ToggleView", if on then "3rd" else "1st")
end

local function onToggle(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		setFirstPerson(not firstPerson)
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("ToggleView", onToggle, true, Enum.KeyCode.V, Enum.KeyCode.ButtonSelect)
setFirstPerson(START_IN_FIRST_PERSON)

-- A new character keeps the Player's CameraMode, but set it again in case another script changed it
player.CharacterAdded:Connect(function()
	setFirstPerson(firstPerson)
end)
