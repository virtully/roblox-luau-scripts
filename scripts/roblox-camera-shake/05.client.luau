--!strict
-- How to make a camera shake in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ShakeSetting
-- LocalScript in StarterPlayerScripts named ShakeSetting.
-- Follows a "CameraShake" attribute on the player, set by your settings menu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type CameraShakeModule = { shake: (number) -> (), enabled: boolean }
local CameraShake = require(ReplicatedStorage:WaitForChild("CameraShake")) :: CameraShakeModule

local player = Players.LocalPlayer

local function apply()
	CameraShake.enabled = player:GetAttribute("CameraShake") ~= false
end

player:GetAttributeChangedSignal("CameraShake"):Connect(apply)
apply()
