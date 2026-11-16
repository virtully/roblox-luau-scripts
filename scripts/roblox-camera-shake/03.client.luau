--!strict
-- How to make a camera shake in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ShakeListener
-- LocalScript in StarterPlayerScripts named ShakeListener.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type CameraShakeModule = { shake: (number) -> (), enabled: boolean }
local CameraShake = require(ReplicatedStorage:WaitForChild("CameraShake")) :: CameraShakeModule
local shakeCamera = ReplicatedStorage:WaitForChild("ShakeCamera") :: RemoteEvent

shakeCamera.OnClientEvent:Connect(function(amount: unknown)
	if typeof(amount) == "number" then
		CameraShake.shake(math.clamp(amount, 0, 1))
	end
end)
