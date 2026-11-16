--!strict
-- How to make a melee hitbox in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-hitbox-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named HitboxTest
-- Script in ServerScriptService named HitboxTest. Delete it after testing.
local BOX_CFRAME = CFrame.new(0, 3, 0) -- the centre of the box
local BOX_SIZE = Vector3.new(8, 6, 8) -- width, height and depth in studs

while true do
	local found: { [Model]: boolean } = {}
	for _, part in workspace:GetPartBoundsInBox(BOX_CFRAME, BOX_SIZE) do
		-- A body part's first Model ancestor is the character
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then
			found[model] = true
		end
	end
	for model in found do
		print(model.Name, "is inside the box")
	end
	task.wait(1)
end
