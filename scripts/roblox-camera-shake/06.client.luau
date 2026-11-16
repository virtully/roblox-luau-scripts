--!strict
-- How to make a camera shake in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named QuickShake
-- LocalScript in StarterCharacterScripts named QuickShake.
local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local function quickShake(duration: number, size: number)
	local stop = os.clock() + duration
	while os.clock() < stop do
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * size, (math.random() - 0.5) * size, 0)
		task.wait()
	end
	humanoid.CameraOffset = Vector3.zero
end

humanoid.HealthChanged:Connect(function(health: number)
	if health < humanoid.MaxHealth then
		quickShake(0.15, 0.6)
	end
end)
