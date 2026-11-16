--!strict
-- How to force first person in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-first-person-lock
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ForcedShoulderLock
-- LocalScript in StarterPlayerScripts named ForcedShoulderLock.
-- Locks the mouse, turns the character with the camera, and puts the camera over the right shoulder.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SHOULDER_OFFSET = Vector3.new(1.75, 0, 0) -- studs right of the character

local player = Players.LocalPlayer

-- Run just after the default camera so its own mouse setting does not win
RunService:BindToRenderStep("ForcedShoulderLock", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	local camera = workspace.CurrentCamera
	if not (humanoid and root and camera) or humanoid.Health <= 0 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	humanoid.AutoRotate = false -- the script turns the character instead of the walk direction
	humanoid.CameraOffset = SHOULDER_OFFSET
	-- Face the way the camera looks, flattened so the character stays upright
	local look = camera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0.01 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
	end
end)
