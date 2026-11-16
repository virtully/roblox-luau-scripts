--!strict
-- How to make a tool in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tool-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Potion Tool named PotionAnimation
-- LocalScript inside the Potion Tool, named PotionAnimation.
local tool = script.Parent :: Tool

local drinkAnimation = Instance.new("Animation")
drinkAnimation.AnimationId = "rbxassetid://0" -- your own animation ID

local track: AnimationTrack? = nil

tool.Equipped:Connect(function()
	local character = tool.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator and drinkAnimation.AnimationId ~= "rbxassetid://0" then
		track = animator:LoadAnimation(drinkAnimation)
	end
end)

tool.Activated:Connect(function()
	if track then
		track:Play()
	end
end)

tool.Unequipped:Connect(function()
	if track then
		track:Stop()
	end
	track = nil
end)
