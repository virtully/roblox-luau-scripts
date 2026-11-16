--!strict
-- How to make NPC dialogue in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-dialogue
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named NpcFacePlayer
-- Turns an NPC to face the player who presses its Talk prompt.
-- Works next to DialogueService without changing it: it listens for any
-- prompt named TalkPrompt, which DialogueService puts in each NPC's HumanoidRootPart.
local ProximityPromptService = game:GetService("ProximityPromptService")

local function faceTowards(npc: Model, npcRoot: BasePart, player: Player)
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not (playerRoot and playerRoot:IsA("BasePart")) then
		return
	end
	-- Look at the player at the NPC's own height, so it turns without tipping over
	local target = Vector3.new(playerRoot.Position.X, npcRoot.Position.Y, playerRoot.Position.Z)
	if (target - npcRoot.Position).Magnitude < 0.1 then
		return -- standing on the same spot: no direction to face
	end
	local facing = CFrame.lookAt(npcRoot.Position, target)
	-- Turn the whole model, keeping its pivot where it sits relative to the root part
	npc:PivotTo(facing * npcRoot.CFrame:ToObjectSpace(npc:GetPivot()))
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if prompt.Name ~= "TalkPrompt" then
		return
	end
	local npcRoot = prompt.Parent
	local npc = npcRoot and npcRoot.Parent
	if npcRoot and npcRoot:IsA("BasePart") and npc and npc:IsA("Model") then
		faceTowards(npc, npcRoot, player)
	end
end)
