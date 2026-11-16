--!strict
-- How to make a gun in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gun-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Blaster Tool in StarterPack named GunTrigger
-- LocalScript inside a gun Tool, named GunTrigger.
-- Sends the aim point to the server for each shot. With AUTOMATIC on, it keeps
-- firing while the mouse button, the trigger or a finger stays down.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Settings
local REMOTE_NAME = "GunFire" -- "LauncherFire" for the launcher below
local FIRE_INTERVAL = 0.1 -- the same value as on the server
local AUTOMATIC = true -- false: one shot per click or tap
local AIM_DISTANCE = 1000

local tool = script.Parent :: Tool
local fireEvent = ReplicatedStorage:WaitForChild(REMOTE_NAME) :: RemoteEvent

local player = Players.LocalPlayer
local lastShot = 0
local lastTouch: Vector2? = nil
local triggerHeld = false

-- Phones have no mouse, so remember where the last tap on the 3D world was
UserInputService.TouchStarted:Connect(function(touch: InputObject, processedByUI: boolean)
	if not processedByUI then
		lastTouch = Vector2.new(touch.Position.X, touch.Position.Y)
	end
end)

-- The same aim as GunClient: the pointer, the last tap, or the centre of the screen
local function getAimPoint(): Vector3
	local camera = workspace.CurrentCamera
	local ray: Ray
	local input = UserInputService.PreferredInput
	if input == Enum.PreferredInput.Touch and lastTouch then
		ray = camera:ScreenPointToRay(lastTouch.X, lastTouch.Y)
	elseif input == Enum.PreferredInput.KeyboardAndMouse then
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	else
		local size = camera.ViewportSize
		ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
	end
	local params = RaycastParams.new()
	params.ExcludeInstances = { player.Character :: Model }
	local result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	return if result then result.Position else ray.Origin + ray.Direction * AIM_DISTANCE
end

local function fireOnce()
	local now = os.clock()
	if now - lastShot < FIRE_INTERVAL then
		return
	end
	lastShot = now
	fireEvent:FireServer(getAimPoint())
end

tool.Activated:Connect(function()
	if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		task.wait() -- one frame, so TouchStarted has recorded this tap
	end
	if not AUTOMATIC then
		fireOnce()
		return
	end
	if triggerHeld then
		return -- already firing
	end
	triggerHeld = true
	-- Keep firing while the trigger is held and the gun is still in the player's hand
	while triggerHeld and tool.Parent == player.Character do
		fireOnce()
		task.wait(FIRE_INTERVAL)
	end
	triggerHeld = false
end)

-- Deactivated fires when the button is released or the finger lifts
tool.Deactivated:Connect(function()
	triggerHeld = false
end)
tool.Unequipped:Connect(function()
	triggerHeld = false
end)
