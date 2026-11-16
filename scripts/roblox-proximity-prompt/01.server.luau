--!strict
-- How to make a press E to interact prompt in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-proximity-prompt
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ChestPrompts
-- Script in ServerScriptService named ChestPrompts.
-- Every part tagged "Chest" gets a hold-E prompt that pays coins once per player.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local CHEST_TAG = "Chest"
local CHEST_COINS = 25
local HOLD_SECONDS = 0.5
local MAX_DISTANCE = 10 -- studs, the prompt's MaxActivationDistance

local opened: { [Player]: { [Instance]: boolean } } = {}

local function giveCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
	end
end

local function setUpChest(chest: Instance)
	if not chest:IsA("BasePart") or chest:FindFirstChild("ChestPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChestPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = "Chest"
	prompt.HoldDuration = HOLD_SECONDS
	prompt.MaxActivationDistance = MAX_DISTANCE
	prompt.Parent = chest

	prompt.Triggered:Connect(function(player: Player)
		-- Prompts can be abused like remotes, so check again on the server
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if not (humanoid and root) or humanoid.Health <= 0 then
			return
		end
		if (root.Position - chest.Position).Magnitude > MAX_DISTANCE + 4 then
			return -- too far to have used the prompt honestly
		end
		local playerOpened = opened[player]
		if not playerOpened or playerOpened[chest] then
			return -- already opened by this player
		end
		playerOpened[chest] = true
		giveCoins(player, CHEST_COINS)
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	opened[player] = {}
end)
for _, player in Players:GetPlayers() do
	opened[player] = {}
end
Players.PlayerRemoving:Connect(function(player: Player)
	opened[player] = nil
end)

for _, chest in CollectionService:GetTagged(CHEST_TAG) do
	setUpChest(chest)
end
CollectionService:GetInstanceAddedSignal(CHEST_TAG):Connect(setUpChest)
