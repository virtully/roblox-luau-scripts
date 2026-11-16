--!strict
-- How to raycast in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-raycast
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named GroundCheck
-- LocalScript in StarterCharacterScripts named GroundCheck.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type RayHelpersModule = {
	excluding: (ignore: { Instance }) -> RaycastParams,
	characterOf: (hit: Instance) -> Model?,
}
local RayHelpers = require(ReplicatedStorage:WaitForChild("RayHelpers")) :: RayHelpersModule

local character = script.Parent :: Model
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local params = RayHelpers.excluding({ character })

while character.Parent do
	-- root part centre to feet is about 3 studs on a standard character; look a little further
	local result = workspace:Raycast(root.Position, Vector3.new(0, -4, 0), params)
	if result then
		print("Standing on", result.Instance.Name, result.Material.Name)
	else
		print("In the air")
	end
	task.wait(0.5)
end
