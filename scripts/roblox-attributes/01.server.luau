--!strict
-- How to use attributes in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-attributes
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named DamagePart
-- Script inside a Part with a number attribute "Damage".
local part = script.Parent :: BasePart

-- A number attribute, with a default when it is missing or not a number
local function numberAttribute(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local damage = numberAttribute(part, "Damage", 10)
print("This part deals", damage, "damage")

-- Set an attribute from code (it appears in the Properties window during Play)
part:SetAttribute("TimesTouched", 0)

part.Touched:Connect(function(hit: BasePart)
	local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(damage)
		part:SetAttribute("TimesTouched", numberAttribute(part, "TimesTouched", 0) + 1)
	end
end)

-- All attributes at once, as a table
for name, value in part:GetAttributes() do
	print(name, "=", value)
end
