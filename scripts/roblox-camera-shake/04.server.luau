--!strict
-- How to make a camera shake in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Quakes
-- Script in ServerScriptService named Quakes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shakeCamera = ReplicatedStorage:WaitForChild("ShakeCamera") :: RemoteEvent

-- Shake every player within radius of position; full strength at the centre.
local function shakeNear(position: Vector3, radius: number, strength: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local distance = (root.Position - position).Magnitude
			if distance < radius then
				shakeCamera:FireClient(player, strength * (1 - distance / radius))
			end
		end
	end
end

-- Example: an explosion every 10 seconds at the Bomb part
local bomb = workspace:WaitForChild("Bomb") :: BasePart
while true do
	task.wait(10)
	local explosion = Instance.new("Explosion")
	explosion.Position = bomb.Position
	explosion.BlastPressure = 0 -- visual only, for this example
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	shakeNear(bomb.Position, 40, 0.8)
end
