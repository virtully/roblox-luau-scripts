--!strict
-- How to play an animation in Roblox Studio with a script
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-animation-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named EmoteOnKey
-- LocalScript in StarterPlayer > StarterCharacterScripts named EmoteOnKey.
-- Press E to play an animation on your own character. Everyone in the server sees it.
local UserInputService = game:GetService("UserInputService")

local ANIMATION_ID = "rbxassetid://507770239" -- Roblox's own R15 wave; put your animation's ID here
local KEY = Enum.KeyCode.E
local COOLDOWN_SECONDS = 1

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID
local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Action -- above walking and idle, so the legs keep walking but the arms wave

local lastPlayed = -math.huge

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	-- gameProcessed is true while the player types in chat or a text box
	if gameProcessed or input.KeyCode ~= KEY then
		return
	end
	if humanoid.Health <= 0 or os.clock() - lastPlayed < COOLDOWN_SECONDS then
		return
	end
	lastPlayed = os.clock()
	track:Play(0.1) -- fade in over 0.1 seconds
end)
