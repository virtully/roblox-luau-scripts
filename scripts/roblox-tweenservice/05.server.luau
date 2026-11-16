--!strict
-- TweenService tutorial: move, rotate and fade parts
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tweenservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Model in Workspace named Elevator
-- Script inside a Model named Elevator.
-- Moves the whole model 20 studs up and back, every part together.
local TweenService = game:GetService("TweenService")

local elevator = script.Parent :: Model
local startPivot = elevator:GetPivot()
local endPivot = startPivot * CFrame.new(0, 20, 0)

local progress = Instance.new("NumberValue")
progress.Changed:Connect(function(alpha: number)
	elevator:PivotTo(startPivot:Lerp(endPivot, alpha))
end)

local info = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 2)
TweenService:Create(progress, info, { Value = 1 }):Play()
