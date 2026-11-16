--!strict
-- How to play an animation in Roblox Studio with a script
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-animation-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named DanceToggle
-- LocalScript in StarterPlayer > StarterCharacterScripts named DanceToggle.
-- Press G to start a looping dance, press G again (or walk) to stop it.
local UserInputService = game:GetService("UserInputService")

local DANCE_ID = "rbxassetid://507771019" -- Roblox's own R15 dance; put your animation's ID here
local KEY = Enum.KeyCode.G

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

local animation = Instance.new("Animation")
animation.AnimationId = DANCE_ID
local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Action
track.Looped = true

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or input.KeyCode ~= KEY then
		return
	end
	if track.IsPlaying then
		track:Stop(0.2)
	else
		track:Play(0.2)
	end
end)

-- Stop dancing when the player starts walking
humanoid.Running:Connect(function(speed: number)
	if speed > 0.5 and track.IsPlaying then
		track:Stop(0.2)
	end
end)
