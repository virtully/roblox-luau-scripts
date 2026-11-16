--!strict
-- How to detect and kick AFK players in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-afk-kick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named AfkReporter
-- LocalScript in StarterPlayerScripts named AfkReporter.
-- Tells the server when this player goes idle (Player.Idled) and when they come back.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local afkStatus = ReplicatedStorage:WaitForChild("AfkStatus") :: RemoteEvent

local reportedIdle = false

-- Fires about 2 minutes after the player stops giving input, then every 30 seconds
player.Idled:Connect(function(_idleSeconds: number)
	if not reportedIdle then
		reportedIdle = true
		afkStatus:FireServer(true)
	end
end)

-- Idled has no "came back" event, so the next input counts as coming back
local function onInput(input: InputObject)
	if not reportedIdle then
		return
	end
	local kind = input.UserInputType
	if kind == Enum.UserInputType.Keyboard
		or kind == Enum.UserInputType.MouseButton1
		or kind == Enum.UserInputType.MouseButton2
		or kind == Enum.UserInputType.MouseMovement
		or kind == Enum.UserInputType.Touch
		or kind == Enum.UserInputType.Gamepad1
	then
		reportedIdle = false
		afkStatus:FireServer(false)
	end
end

UserInputService.InputBegan:Connect(onInput)
UserInputService.InputChanged:Connect(onInput)
