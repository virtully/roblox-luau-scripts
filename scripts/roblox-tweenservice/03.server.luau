--!strict
-- TweenService tutorial: move, rotate and fade parts
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tweenservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named FadingWall
-- Script inside a Part named FadingWall.
local TweenService = game:GetService("TweenService")

local wall = script.Parent :: BasePart

-- turn a quarter around the part's own up axis in 1 second
local turn = TweenService:Create(wall, TweenInfo.new(1), {
	CFrame = wall.CFrame * CFrame.Angles(0, math.rad(90), 0),
})
turn:Play()
turn.Completed:Wait() -- carry on only once it has finished

-- then fade out and shrink at the same time
local fade = TweenService:Create(wall, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	Transparency = 1,
	Size = wall.Size * 0.2,
})
fade:Play()
fade.Completed:Wait()
wall:Destroy()
