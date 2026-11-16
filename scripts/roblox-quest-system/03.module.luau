--!strict
-- How to make a quest system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-quest-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named CreatorTag
-- ModuleScript in ServerScriptService named CreatorTag.
-- Weapons call it before dealing damage: require(ServerScriptService.CreatorTag)(humanoid, player)
local Debris = game:GetService("Debris")

local TAG_SECONDS = 2 -- the hit counts for this long

local function tagHumanoid(humanoid: Humanoid, attacker: Player)
	local old = humanoid:FindFirstChild("creator")
	if old then
		old:Destroy()
	end
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = attacker
	tag.Parent = humanoid
	Debris:AddItem(tag, TAG_SECONDS)
end

return tagHumanoid
