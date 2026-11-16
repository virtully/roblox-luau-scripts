--!strict
-- How to make a kill feed and kill counter in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-feed
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named CreatorTag
-- ModuleScript in ServerScriptService named CreatorTag.
-- Weapons call it before dealing damage: CreatorTag(humanoid, attacker, "Sword")
local Debris = game:GetService("Debris")

local TAG_SECONDS = 5 -- the hit counts as the kill for this long

local function tagHumanoid(humanoid: Humanoid, attacker: Player, weaponName: string?)
	local old = humanoid:FindFirstChild("creator")
	if old then
		old:Destroy()
	end
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = attacker
	if weaponName then
		tag:SetAttribute("Weapon", weaponName)
	end
	tag.Parent = humanoid
	-- Debris removes the tag after TAG_SECONDS without needing a loop
	Debris:AddItem(tag, TAG_SECONDS)
end

return tagHumanoid
