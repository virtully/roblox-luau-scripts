--!strict
-- How to make an obby game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-obby-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ObbyObstacles
-- Script in ServerScriptService named ObbyObstacles.
-- One script for every obstacle: tag a part "Fade" or "Spin" and it works.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FADE_DELAY = 0.6 -- seconds a Fade platform holds after the first touch
local FADE_GONE = 2 -- seconds it stays gone before coming back
local SPIN_SPEED = 90 -- degrees per second, unless the part has a SpinSpeed attribute

local function setupFade(part: BasePart)
	local busy = false
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if busy or not (character and character:IsA("Model")) or not Players:GetPlayerFromCharacter(character) then
			return
		end
		busy = true
		local start = part.Transparency
		part.Transparency = 0.5 -- warn the player
		task.wait(FADE_DELAY)
		part.Transparency = 1
		part.CanCollide = false
		task.wait(FADE_GONE)
		part.Transparency = start
		part.CanCollide = true
		busy = false
	end)
end

local spinners: { [BasePart]: CFrame } = {}

local function setupSpin(part: BasePart)
	part.Anchored = true
	spinners[part] = part.CFrame
end

for _, part in CollectionService:GetTagged("Fade") do
	if part:IsA("BasePart") then
		setupFade(part)
	end
end
for _, part in CollectionService:GetTagged("Spin") do
	if part:IsA("BasePart") then
		setupSpin(part)
	end
end

-- Turn every spinner from its starting CFrame, so they never drift apart
RunService.Heartbeat:Connect(function()
	local now = workspace:GetServerTimeNow()
	for part, origin in spinners do
		if not part.Parent then
			spinners[part] = nil
			continue
		end
		local speed = part:GetAttribute("SpinSpeed")
		local degrees = (if typeof(speed) == "number" then speed else SPIN_SPEED) * now
		part.CFrame = origin * CFrame.Angles(0, math.rad(degrees % 360), 0)
	end
end)
