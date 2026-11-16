--!strict
-- How to use CollectionService tags in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-collectionservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LavaParts
-- Script in ServerScriptService named LavaParts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type TagBinderModule = { bind: (string, (Instance) -> (() -> ())?) -> () -> () }
local TagBinder = require(ReplicatedStorage:WaitForChild("TagBinder")) :: TagBinderModule

TagBinder.bind("Lava", function(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local connection = instance.Touched:Connect(function(hit: BasePart)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
	return function()
		connection:Disconnect()
	end
end)
