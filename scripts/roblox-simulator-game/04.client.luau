--!strict
-- How to make a simulator game on Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-simulator-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Dumbbell Tool in StarterPack named LiftClient
-- LocalScript inside the Dumbbell Tool, named LiftClient.
-- Each lift is a click: it fires the same Click remote as the button, and the server
-- decides what it is worth and how many count.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent :: Tool
local remotes = ReplicatedStorage:WaitForChild("SimulatorRemotes")
local clickEvent = remotes:WaitForChild("Click") :: RemoteEvent

local LIFT_SECONDS = 0.5 -- time between lifts on this device; the server has its own cap
local LIFT_ANIMATION_ID = "" -- optional: "rbxassetid://" followed by your animation's id

local player = Players.LocalPlayer
local lastLift = 0
local liftTrack: AnimationTrack? = nil
local trackCharacter: Model? = nil

-- Load the lift animation once per character, through the Animator Roblox put in the Humanoid
local function loadLift()
	local character = player.Character
	if LIFT_ANIMATION_ID == "" or not character or character == trackCharacter then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = LIFT_ANIMATION_ID
		liftTrack = animator:LoadAnimation(animation)
		trackCharacter = character
	end
end

tool.Equipped:Connect(loadLift)

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastLift < LIFT_SECONDS then
		return
	end
	lastLift = now
	if liftTrack then
		liftTrack:Play()
	end
	clickEvent:FireServer() -- no arguments: the server works out the reward
end)
