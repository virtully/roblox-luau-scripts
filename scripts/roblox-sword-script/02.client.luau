--!strict
-- How to make a sword in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sword-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Sword Tool in StarterPack named SwordClient
-- LocalScript inside the Sword Tool, named SwordClient.
-- Tool.Activated fires on the player's device, so this script listens for the click,
-- tap or trigger, plays the swing animation and asks the server to swing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent :: Tool
local swingEvent = ReplicatedStorage:WaitForChild("SwordSwing") :: RemoteEvent

local COOLDOWN_SECONDS = 0.6 -- the same value as in SwordService
local SWING_ANIMATION_ID = "" -- optional: "rbxassetid://" followed by your animation's id

local player = Players.LocalPlayer
local lastSwing = 0
local swingTrack: AnimationTrack? = nil
local trackCharacter: Model? = nil

-- Load the animation once per character. Animations started on your own character
-- from your device are shown to every player.
local function loadSwing()
	local character = player.Character
	if SWING_ANIMATION_ID == "" or not character or character == trackCharacter then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = SWING_ANIMATION_ID
		swingTrack = animator:LoadAnimation(animation)
		trackCharacter = character
	end
end

tool.Equipped:Connect(loadSwing)

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastSwing < COOLDOWN_SECONDS then
		return -- the server enforces this too; checking here avoids wasted requests
	end
	lastSwing = now
	if swingTrack then
		swingTrack:Play()
	end
	swingEvent:FireServer()
end)
