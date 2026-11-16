--!strict
-- How to make a kill brick (lava) in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-brick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Lava part named RisingLava
-- Script inside a lava part, named RisingLava.
-- The lava climbs, waits, sinks and repeats. Anyone below its top surface dies.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RISE_STUDS = 40 -- how far the lava climbs
local RISE_SECONDS = 60 -- how long the climb takes
local PAUSE_SECONDS = 5 -- wait at the top and the bottom

local lava = script.Parent :: BasePart
lava.Anchored = true
local bottom = lava.CFrame
local top = bottom + Vector3.new(0, RISE_STUDS, 0)

-- A moving anchored part does not always fire Touched on a player who stands still,
-- so check every frame whether each character's root is inside the lava
RunService.Heartbeat:Connect(function()
	local half = lava.Size / 2
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if humanoid and root and humanoid.Health > 0 then
			-- The root's position in the lava's own space: inside when every axis is within half its size
			local offset = lava.CFrame:PointToObjectSpace(root.Position)
			if math.abs(offset.X) <= half.X and math.abs(offset.Z) <= half.Z and offset.Y <= half.Y then
				humanoid.Health = 0
			end
		end
	end
end)

local riseInfo = TweenInfo.new(RISE_SECONDS, Enum.EasingStyle.Linear)
local fallInfo = TweenInfo.new(RISE_SECONDS / 4, Enum.EasingStyle.Sine)

while true do
	local rise = TweenService:Create(lava, riseInfo, { CFrame = top })
	rise:Play()
	rise.Completed:Wait()
	task.wait(PAUSE_SECONDS)
	local fall = TweenService:Create(lava, fallInfo, { CFrame = bottom })
	fall:Play()
	fall.Completed:Wait()
	task.wait(PAUSE_SECONDS)
end
