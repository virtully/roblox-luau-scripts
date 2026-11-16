--!strict
-- How to make an egg hatching system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-egg-hatching
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named EggHatching
-- Script in ServerScriptService named EggHatching.
-- Every Model tagged "Egg" gets a ProximityPrompt. The server checks the price,
-- takes the coins, rolls the pet and adds it to the player's Pets folder.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type PetChance = { pet: string, weight: number, rarity: string }
type Egg = { price: number, pets: { PetChance } }
local EggConfig = require(ReplicatedStorage:WaitForChild("EggConfig")) :: { [string]: Egg }

local HATCH_COOLDOWN = 3.5 -- seconds between hatches, the length of the animation

local hatchedEvent = Instance.new("RemoteEvent")
hatchedEvent.Name = "EggHatched"
hatchedEvent.Parent = ReplicatedStorage

local random = Random.new()
local lastHatch: { [Player]: number } = {}

local function roll(egg: Egg): PetChance
	local total = 0
	for _, chance in egg.pets do
		total += chance.weight
	end
	local pick = random:NextNumber(0, total)
	for _, chance in egg.pets do
		pick -= chance.weight
		if pick <= 0 then
			return chance
		end
	end
	return egg.pets[#egg.pets]
end

local function hatch(player: Player, eggName: string)
	local egg = EggConfig[eggName]
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local pets = player:FindFirstChild("Pets")
	if not (egg and coins and coins:IsA("IntValue") and pets) then
		return
	end
	local now = os.clock()
	if now - (lastHatch[player] or -math.huge) < HATCH_COOLDOWN then
		return
	end
	if coins.Value < egg.price then
		hatchedEvent:FireClient(player, eggName, nil)
		return
	end
	lastHatch[player] = now
	coins.Value -= egg.price -- take the price before rolling, in the same step

	local result = roll(egg)
	local owned = pets:FindFirstChild(result.pet)
	if owned and owned:IsA("IntValue") then
		owned.Value += 1
	else
		local newPet = Instance.new("IntValue")
		newPet.Name = result.pet
		newPet.Value = 1
		newPet.Parent = pets
	end
	hatchedEvent:FireClient(player, eggName, result.pet, result.rarity)
end

local function setUpEgg(eggModel: Instance)
	local eggName = eggModel:GetAttribute("EggName")
	if typeof(eggName) ~= "string" or not EggConfig[eggName] then
		warn("EggHatching: give", eggModel:GetFullName(), "an EggName attribute that matches EggConfig")
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = string.format("Hatch (%d coins)", EggConfig[eggName].price)
	prompt.ObjectText = eggName
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = if eggModel:IsA("Model") then eggModel.PrimaryPart or eggModel else eggModel
	prompt.Triggered:Connect(function(player: Player)
		hatch(player, eggName)
	end)
end

for _, egg in CollectionService:GetTagged("Egg") do
	setUpEgg(egg)
end
CollectionService:GetInstanceAddedSignal("Egg"):Connect(setUpEgg)

Players.PlayerAdded:Connect(function(player: Player)
	local pets = Instance.new("Folder")
	pets.Name = "Pets"
	pets.Parent = player
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastHatch[player] = nil
end)
