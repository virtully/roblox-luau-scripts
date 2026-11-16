--!strict
-- How to make an elevator in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-elevator-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Elevator Model named ElevatorDoors
-- Script inside the Elevator Model, named ElevatorDoors.
-- Slides open the door whose DoorFloor matches the car's CurrentFloor, closes the others.
local TweenService = game:GetService("TweenService")

local OPEN_OFFSET = Vector3.new(0, 0, 6) -- how far a door slides, in the door's own space
local SLIDE_SECONDS = 0.6

local elevator = script.Parent :: Model
local doorsFolder = elevator:WaitForChild("Doors")

local closedCFrames: { [BasePart]: CFrame } = {}
for _, door in doorsFolder:GetChildren() do
	if door:IsA("BasePart") then
		door.Anchored = true
		closedCFrames[door] = door.CFrame
	end
end

local tweenInfo = TweenInfo.new(SLIDE_SECONDS, Enum.EasingStyle.Quad)

local function update()
	local floor = elevator:GetAttribute("CurrentFloor")
	for door, closed in closedCFrames do
		local open = door:GetAttribute("DoorFloor") == floor
		local goal = if open then closed * CFrame.new(OPEN_OFFSET) else closed
		TweenService:Create(door, tweenInfo, { CFrame = goal }):Play()
	end
end

elevator:GetAttributeChangedSignal("CurrentFloor"):Connect(update)
update()
