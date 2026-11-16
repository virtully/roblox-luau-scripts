--!strict
-- How to play an animation in Roblox Studio with a script
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-animation-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named PunchOnClick
-- LocalScript in StarterPlayer > StarterCharacterScripts named PunchOnClick.
-- Plays your punch animation on a click and tells the server the moment the fist lands,
-- using an animation event named "Hit" that you add in the Animation Editor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PUNCH_ID = "rbxassetid://0" -- your own punch animation, with a "Hit" event at the moment of impact
local COOLDOWN_SECONDS = 0.6

local punchHit = ReplicatedStorage:WaitForChild("PunchHit") :: RemoteEvent
local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

local animation = Instance.new("Animation")
animation.AnimationId = PUNCH_ID
local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Action

track:GetMarkerReachedSignal("Hit"):Connect(function()
	punchHit:FireServer() -- the server checks range and cooldown before it deals damage
end)

local lastPunch = -math.huge
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if os.clock() - lastPunch < COOLDOWN_SECONDS then
		return
	end
	lastPunch = os.clock()
	track:Play(0.05)
end)
