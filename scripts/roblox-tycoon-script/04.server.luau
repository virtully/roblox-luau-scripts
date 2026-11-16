--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TycoonConveyors
local tycoons = workspace:WaitForChild("Tycoons")

local DEFAULT_SPEED = 8 -- studs per second

-- An anchored part never moves, but a velocity on it carries whatever rests on top
local function startConveyor(part: BasePart)
	local speed = part:GetAttribute("Speed")
	local studsPerSecond = if typeof(speed) == "number" then speed else DEFAULT_SPEED
	part.Anchored = true
	part.AssemblyLinearVelocity = part.CFrame.LookVector * studsPerSecond
end

local function onDescendant(instance: Instance)
	if instance.Name == "Conveyor" and instance:IsA("BasePart") then
		startConveyor(instance)
	end
end

for _, instance in tycoons:GetDescendants() do
	onDescendant(instance)
end

-- A conveyor sold by a button comes back into its plot later, so watch for it too
tycoons.DescendantAdded:Connect(onDescendant)
