--!strict
-- How to make a fireball in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fireball-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named FireballKey
-- LocalScript in StarterPlayerScripts named FireballKey.
-- Q on a keyboard, Y on a gamepad, or an on-screen button on a phone casts a fireball.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local castEvent = ReplicatedStorage:WaitForChild("CastFireball") :: RemoteEvent

local COOLDOWN = 1.5 -- the same value as in FireballService
local AIM_DISTANCE = 1000

local player = Players.LocalPlayer
local lastCast = 0

local function getAimPoint(): Vector3
	local camera = workspace.CurrentCamera
	local point: Vector2
	if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		point = UserInputService:GetMouseLocation()
	else -- gamepad and touch aim at the centre of the screen
		point = camera.ViewportSize / 2
	end
	local ray = camera:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	local character = player.Character
	params.ExcludeInstances = if character then { character } else {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	return if result then result.Position else ray.Origin + ray.Direction * AIM_DISTANCE
end

local function onCast(_actionName: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local now = os.clock()
	if now - lastCast >= COOLDOWN then
		lastCast = now
		castEvent:FireServer(getAimPoint())
	end
	return Enum.ContextActionResult.Sink
end

-- true adds a touch button on phones and tablets
ContextActionService:BindAction("CastFireball", onCast, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("CastFireball", "Fire")
