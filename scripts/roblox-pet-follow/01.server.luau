--!strict
-- How to make a pet that follows you in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-pet-follow
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PetFollow
-- Script in ServerScriptService named PetFollow.
-- Gives every player a copy of ServerStorage.Pet that floats beside them.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local OFFSET = Vector3.new(3, 1, 2) -- studs right, up and behind the player
local RESPONSIVENESS = 15 -- higher follows more tightly, lower drifts behind more

local petTemplate = ServerStorage:WaitForChild("Pet") :: Model

local function givePet(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local pet = petTemplate:Clone()
	local petRoot = pet.PrimaryPart
	if not petRoot then
		warn("PetFollow: set the PrimaryPart of ServerStorage.Pet")
		return
	end

	-- The pet must not push the player around or weigh them down
	for _, part in pet:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	-- Two attachments: one in the pet, one beside the player where the pet should be
	local petAttachment = Instance.new("Attachment")
	petAttachment.Parent = petRoot
	local target = Instance.new("Attachment")
	target.Name = "PetTarget"
	target.Position = OFFSET
	target.Parent = root

	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = target
	align.Responsiveness = RESPONSIVENESS
	align.MaxForce = 100000
	align.Parent = petRoot

	local turn = Instance.new("AlignOrientation")
	turn.Attachment0 = petAttachment
	turn.Attachment1 = target
	turn.Responsiveness = RESPONSIVENESS
	turn.MaxTorque = 100000
	turn.Parent = petRoot

	pet.Name = player.Name .. "Pet"
	pet:PivotTo(root.CFrame * CFrame.new(OFFSET))
	pet.Parent = character -- destroyed with the character on respawn
	-- The player's device already simulates their character, so let it move the pet too
	petRoot:SetNetworkOwner(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		givePet(player, character)
	end)
end)
