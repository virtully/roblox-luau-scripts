--!strict
-- How to make a melee hitbox in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-hitbox-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a boss NPC Model named BossSlam
-- Script inside a boss NPC Model, named BossSlam.
local ServerScriptService = game:GetService("ServerScriptService")

type HitboxModule = {
	run: (follow: BasePart, options: {
		size: Vector3,
		offset: CFrame,
		duration: number,
		exclude: { Instance },
		showDebug: boolean?,
	}, onHit: (character: Model, humanoid: Humanoid) -> ()) -> () -> (),
}
local Hitbox = require(ServerScriptService:WaitForChild("Hitbox")) :: HitboxModule

local SLAM_DAMAGE = 35
local SLAM_EVERY = 6 -- seconds between slams

local boss = script.Parent :: Model
local root = boss:WaitForChild("HumanoidRootPart") :: BasePart

while true do
	task.wait(SLAM_EVERY)
	Hitbox.run(root, {
		size = Vector3.new(18, 4, 18), -- wide and flat, around the boss
		offset = CFrame.new(0, -2, 0), -- slightly below the root, at the boss's feet
		duration = 0.25,
		exclude = { boss },
	}, function(_character: Model, humanoid: Humanoid)
		humanoid:TakeDamage(SLAM_DAMAGE)
	end)
end
