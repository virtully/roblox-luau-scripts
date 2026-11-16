--!strict
-- How to make a camera shake in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ShakeTest
-- LocalScript in StarterPlayerScripts named ShakeTest.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

type CameraShakeModule = { shake: (number) -> (), enabled: boolean }
local CameraShake = require(ReplicatedStorage:WaitForChild("CameraShake")) :: CameraShakeModule

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.K then
		CameraShake.shake(0.5)
	end
end)
