--!strict
-- How to make a horror game in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-horror-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named FlashlightInput
-- LocalScript in StarterPlayerScripts named FlashlightInput.
-- Press F to ask the server to switch the flashlight.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local toggle = ReplicatedStorage:WaitForChild("ToggleFlashlight") :: RemoteEvent

UserInputService.InputBegan:Connect(function(input, typing)
	if not typing and input.KeyCode == Enum.KeyCode.F then
		toggle:FireServer()
	end
end)
