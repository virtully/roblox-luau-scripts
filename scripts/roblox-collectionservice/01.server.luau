--!strict
-- How to use CollectionService tags in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-collectionservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Spinners
-- Script in ServerScriptService named Spinners.
-- Every part tagged "Spinner" turns slowly.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Spinner"
local DEGREES_PER_SECOND = 90

local spinning: { [BasePart]: boolean } = {}

local function onAdded(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Anchored = true
		spinning[instance] = true
	end
end

local function onRemoved(instance: Instance)
	if instance:IsA("BasePart") then
		spinning[instance] = nil
	end
end

for _, instance in CollectionService:GetTagged(TAG) do
	onAdded(instance)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(onAdded)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(onRemoved)

RunService.Heartbeat:Connect(function(deltaTime: number)
	local turn = CFrame.Angles(0, math.rad(DEGREES_PER_SECOND * deltaTime), 0)
	for part in spinning do
		part.CFrame *= turn
	end
end)
