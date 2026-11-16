--!strict
-- TweenService tutorial: move, rotate and fade parts
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tweenservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named Rise
-- Script inside a Part.
local TweenService = game:GetService("TweenService")

local part = script.Parent :: BasePart

local info = TweenInfo.new(2) -- 2 seconds, default easing
local goal = { Position = part.Position + Vector3.new(0, 10, 0) }

local tween = TweenService:Create(part, info, goal)
tween:Play()
