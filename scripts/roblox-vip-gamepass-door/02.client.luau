--!strict
-- How to make a VIP game pass door in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-vip-gamepass-door
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named VipDoorClient
-- LocalScript in StarterPlayerScripts named VipDoorClient.
-- Prompts the VIP pass when a non-owner touches a VIP door, and fades the door for owners. Looks only.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PROMPT_COOLDOWN = 5 -- seconds between purchase windows
local OWNER_FADE = 0.6 -- extra transparency an owner sees on the door

local player = Players.LocalPlayer
local lastPrompt = 0

local function ownsVip(): boolean
	return player:GetAttribute("OwnsVip") == true
end

local function updateLook(door: BasePart)
	-- LocalTransparencyModifier only changes what this player sees
	door.LocalTransparencyModifier = if ownsVip() then OWNER_FADE else 0
end

local function setUpDoor(door: Instance)
	if not door:IsA("BasePart") then
		return
	end
	updateLook(door)
	door.Touched:Connect(function(hit: BasePart)
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) or ownsVip() then
			return
		end
		local passId = door:GetAttribute("VipPassId")
		if type(passId) ~= "number" or passId == 0 then
			return
		end
		local now = os.clock()
		if now - lastPrompt < PROMPT_COOLDOWN then
			return
		end
		lastPrompt = now
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end)
end

for _, door in CollectionService:GetTagged("VipDoor") do
	setUpDoor(door)
end
CollectionService:GetInstanceAddedSignal("VipDoor"):Connect(setUpDoor)

-- When the server grants the pass, fade every door at once
player:GetAttributeChangedSignal("OwnsVip"):Connect(function()
	for _, door in CollectionService:GetTagged("VipDoor") do
		if door:IsA("BasePart") then
			updateLook(door)
		end
	end
end)
