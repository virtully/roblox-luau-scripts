--!strict
-- How to force first person in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-first-person-lock
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named ShowArms
-- LocalScript in StarterCharacterScripts named ShowArms.
-- Keeps your arms visible in first person (R15 and R6 arm names).
local RunService = game:GetService("RunService")

local character = script.Parent :: Model

local ARM_NAMES: { [string]: boolean } = {
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
	RightUpperArm = true, RightLowerArm = true, RightHand = true,
	["Left Arm"] = true, ["Right Arm"] = true,
}

RunService:BindToRenderStep("ShowArms", Enum.RenderPriority.Camera.Value + 1, function()
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and ARM_NAMES[part.Name] then
			part.LocalTransparencyModifier = 0
		end
	end
end)

character.AncestryChanged:Connect(function()
	if not character.Parent then
		RunService:UnbindFromRenderStep("ShowArms")
	end
end)
