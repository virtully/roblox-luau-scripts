--!strict
-- How to use CollectionService tags in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-collectionservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named PickupGlow
-- LocalScript in StarterPlayerScripts named PickupGlow.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type TagBinderModule = { bind: (string, (Instance) -> (() -> ())?) -> () -> () }
local TagBinder = require(ReplicatedStorage:WaitForChild("TagBinder")) :: TagBinderModule

TagBinder.bind("Pickup", function(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 120)
	light.Range = 8
	light.Parent = instance
	return function()
		light:Destroy()
	end
end)
