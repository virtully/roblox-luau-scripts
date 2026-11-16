--!strict
-- How to make a ragdoll on death in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-ragdoll-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RagdollNpcs
-- Add to the bottom of RagdollOnDeath: NPCs tagged "Ragdoll" ragdoll on death too.
local CollectionService = game:GetService("CollectionService")

local function ragdoll(_character: Model, _humanoid: Humanoid)
	-- use the ragdoll function from Step 1
end

local function setUpNpc(npc: Instance)
	if not npc:IsA("Model") then
		return
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.BreakJointsOnDeath = false
	humanoid.Died:Once(function()
		ragdoll(npc, humanoid)
	end)
end

for _, npc in CollectionService:GetTagged("Ragdoll") do
	setUpNpc(npc)
end
CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(setUpNpc)
