--!strict
-- How to make an escape room game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-escape-room-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the LeverPuzzle model named LeverPuzzle
-- Script inside a Model named LeverPuzzle. The model holds Lever1, Lever2, ... (parts)
-- and a part named Door. Pull the levers in the secret order to open the door;
-- one wrong lever resets them all.
local TweenService = game:GetService("TweenService")

local puzzle = script.Parent :: Model
local door = puzzle:WaitForChild("Door") :: BasePart
local ORDER = { 3, 1, 4, 2 } -- the solution: lever numbers in order. Hide clues for it in the room.
local OFF_COLOR = Color3.fromRGB(200, 60, 60)
local ON_COLOR = Color3.fromRGB(80, 210, 110)

local progress = 0 -- how many levers are already right
local solved = false
local levers: { [number]: BasePart } = {}

local function resetLevers()
	progress = 0
	for _, lever in levers do
		lever.Color = OFF_COLOR
	end
end

local function openDoor()
	solved = true
	local goal = { CFrame = door.CFrame * CFrame.new(0, door.Size.Y, 0) }
	TweenService:Create(door, TweenInfo.new(1.5), goal):Play()
	door.CanCollide = false
end

for i = 1, #ORDER do
	local lever = puzzle:WaitForChild("Lever" .. i) :: BasePart
	levers[i] = lever
	lever.Color = OFF_COLOR
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pull"
	prompt.ObjectText = "Lever"
	prompt.Parent = lever
	prompt.Triggered:Connect(function()
		if solved or lever.Color == ON_COLOR then
			return
		end
		if ORDER[progress + 1] == i then
			progress += 1
			lever.Color = ON_COLOR
			if progress == #ORDER then
				openDoor()
			end
		else
			resetLevers() -- wrong lever: everyone starts again
		end
	end)
end
