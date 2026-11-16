--!strict
-- How to raycast in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-raycast
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named RayHelpers
-- ModuleScript in ReplicatedStorage named RayHelpers.
-- Small helpers used by the next steps.
local RayHelpers = {}

-- Params that ignore the given instances (and everything inside them).
function RayHelpers.excluding(ignore: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return params
end

-- The character a hit part belongs to, if any.
function RayHelpers.characterOf(hit: Instance): Model?
	local model = hit:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return model
	end
	return nil
end

return RayHelpers
