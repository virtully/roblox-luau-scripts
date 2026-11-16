--!strict
-- How to play an animation in Roblox Studio with a script
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-animation-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the NPC model named NpcAnimation
-- Script inside the NPC model named NpcAnimation. The NPC needs a Humanoid and a HumanoidRootPart.
-- Plays a looping animation on the NPC from the server, so every player sees it.
local ANIMATION_ID = "rbxassetid://507771019" -- Roblox's own R15 dance; put your animation's ID here

local npc = script.Parent :: Model
local humanoid = npc:WaitForChild("Humanoid") :: Humanoid

-- An NPC made from a rig usually has an Animator already; create one if it does not
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	local newAnimator = Instance.new("Animator")
	newAnimator.Parent = humanoid
	animator = newAnimator
end
assert(animator, "the NPC has no Animator")

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID
local track = animator:LoadAnimation(animation)
track.Looped = true
track:Play()
