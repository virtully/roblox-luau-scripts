--!strict
-- TweenService tutorial: move, rotate and fade parts
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tweenservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named FloatingGem
-- Script inside a Part named Gem. Floats up and down and spins forever.
local TweenService = game:GetService("TweenService")

local FLOAT_HEIGHT = 1.5 -- studs above where you placed it
local FLOAT_SECONDS = 1.2 -- each way
local SPIN_SECONDS = 3 -- one full turn

local gem = script.Parent :: BasePart
gem.Anchored = true
local baseCFrame = gem.CFrame

local height = Instance.new("NumberValue")
local angle = Instance.new("NumberValue")

local function apply()
	gem.CFrame = baseCFrame * CFrame.new(0, height.Value, 0) * CFrame.Angles(0, math.rad(angle.Value), 0)
end
height.Changed:Connect(apply)
angle.Changed:Connect(apply)

TweenService:Create(height, TweenInfo.new(FLOAT_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	Value = FLOAT_HEIGHT,
}):Play()

TweenService:Create(angle, TweenInfo.new(SPIN_SECONDS, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
	Value = 360,
}):Play()
