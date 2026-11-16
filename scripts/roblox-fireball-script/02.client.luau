--!strict
-- How to make a fireball in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fireball-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Fireball Tool in StarterPack named FireballClient
-- LocalScript inside the Fireball Tool, named FireballClient.
-- Works out where the player is aiming and sends that point to the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local tool = script.Parent :: Tool
local castEvent = ReplicatedStorage:WaitForChild("CastFireball") :: RemoteEvent

local COOLDOWN = 1.5 -- the same value as in FireballService
local AIM_DISTANCE = 1000

local player = Players.LocalPlayer
local lastTouch: Vector2? = nil

-- Phones have no mouse, so remember where the last tap on the 3D world was
UserInputService.TouchStarted:Connect(function(touch: InputObject, processedByUI: boolean)
	if not processedByUI then
		lastTouch = Vector2.new(touch.Position.X, touch.Position.Y)
	end
end)

local function getAimPoint(): Vector3
	local camera = workspace.CurrentCamera
	local ray: Ray
	local input = UserInputService.PreferredInput
	if input == Enum.PreferredInput.Touch and lastTouch then
		ray = camera:ScreenPointToRay(lastTouch.X, lastTouch.Y)
	elseif input == Enum.PreferredInput.KeyboardAndMouse then
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	else -- a gamepad, or a phone before its first tap: the centre of the screen
		local size = camera.ViewportSize
		ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
	end
	local params = RaycastParams.new()
	params.ExcludeInstances = { player.Character :: Model }
	local result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	return if result then result.Position else ray.Origin + ray.Direction * AIM_DISTANCE
end

tool.Activated:Connect(function()
	if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		task.wait() -- one frame, so TouchStarted has recorded this tap
	end
	castEvent:FireServer(getAimPoint())
	-- Grey the Tool out locally while it cools down. The server still checks the real cooldown.
	tool.Enabled = false
	task.delay(COOLDOWN, function()
		tool.Enabled = true
	end)
end)
