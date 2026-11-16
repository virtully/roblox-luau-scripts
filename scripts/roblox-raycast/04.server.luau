--!strict
-- How to raycast in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-raycast
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LineOfSight
-- Script in ServerScriptService named LineOfSight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type RayHelpersModule = {
	excluding: (ignore: { Instance }) -> RaycastParams,
	characterOf: (hit: Instance) -> Model?,
}
local RayHelpers = require(ReplicatedStorage:WaitForChild("RayHelpers")) :: RayHelpersModule

local SIGHT_RANGE = 80 -- studs

local function canSee(npc: Model, target: Model): boolean
	local eyes = npc:FindFirstChild("Head")
	local targetHead = target:FindFirstChild("Head")
	if not (eyes and eyes:IsA("BasePart") and targetHead and targetHead:IsA("BasePart")) then
		return false
	end
	local offset = targetHead.Position - eyes.Position
	if offset.Magnitude > SIGHT_RANGE then
		return false
	end
	local result = workspace:Raycast(eyes.Position, offset, RayHelpers.excluding({ npc }))
	return result ~= nil and RayHelpers.characterOf(result.Instance) == target
end

local guard = workspace:WaitForChild("Guard") :: Model

while true do
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and canSee(guard, character) then
			print("Guard sees", player.Name)
		end
	end
	task.wait(0.5)
end
