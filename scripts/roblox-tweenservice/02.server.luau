--!strict
-- TweenService tutorial: move, rotate and fade parts
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tweenservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named Platform
-- Script inside a Part named Platform.
-- Slides back and forth 12 studs forever, easing at both ends.
local TweenService = game:GetService("TweenService")

local platform = script.Parent :: BasePart

local info = TweenInfo.new(
	3, -- seconds each way
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1, -- repeat forever
	true -- come back each time
)

TweenService:Create(platform, info, { Position = platform.Position + Vector3.new(12, 0, 0) }):Play()
