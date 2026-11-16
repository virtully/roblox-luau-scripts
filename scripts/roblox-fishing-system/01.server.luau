--!strict
-- How to make a fishing system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fishing-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FishingService
-- Script in ServerScriptService named FishingService.
-- The rod asks to cast; the server checks the player is by the water, waits for a
-- bite, rolls a fish and pays out. The client never chooses the fish.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_DISTANCE = 12 -- studs from the edge of a part tagged "FishingWater"
local MIN_WAIT, MAX_WAIT = 2, 6 -- seconds before a bite

type Fish = { name: string, weight: number, coins: number }
-- weight is the chance: higher is more common. These add up to 100, so they read as percent.
local FISH: { Fish } = {
	{ name = "Sardine", weight = 50, coins = 5 },
	{ name = "Salmon", weight = 30, coins = 15 },
	{ name = "Pufferfish", weight = 15, coins = 40 },
	{ name = "Golden Koi", weight = 5, coins = 150 },
}

local castEvent = Instance.new("RemoteEvent")
castEvent.Name = "CastLine"
castEvent.Parent = ReplicatedStorage
local resultEvent = Instance.new("RemoteEvent")
resultEvent.Name = "FishingResult"
resultEvent.Parent = ReplicatedStorage

local fishing: { [Player]: boolean } = {}
local random = Random.new()

local function rollFish(): Fish
	local total = 0
	for _, fish in FISH do
		total += fish.weight
	end
	local roll = random:NextNumber(0, total)
	for _, fish in FISH do
		roll -= fish.weight
		if roll <= 0 then
			return fish
		end
	end
	return FISH[#FISH]
end

local function nearWater(position: Vector3): boolean
	for _, water in CollectionService:GetTagged("FishingWater") do
		if water:IsA("BasePart") then
			-- Distance from the position to the water's box, in the water's own space
			local offset = water.CFrame:PointToObjectSpace(position)
			local half = water.Size / 2
			local outside = Vector3.new(
				math.max(math.abs(offset.X) - half.X, 0),
				math.max(math.abs(offset.Y) - half.Y, 0),
				math.max(math.abs(offset.Z) - half.Z, 0)
			)
			if outside.Magnitude <= MAX_DISTANCE then
				return true
			end
		end
	end
	return false
end

local function addStat(player: Player, statName: string, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	if stat and stat:IsA("IntValue") then
		stat.Value += amount
	end
end

castEvent.OnServerEvent:Connect(function(player: Player)
	local character = player.Character
	local rod = character and character:FindFirstChild("FishingRod")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	-- Must be alive, holding the rod, by the water and not already fishing
	if not (rod and rod:IsA("Tool") and humanoid and root) or humanoid.Health <= 0 or fishing[player] then
		return
	end
	if not nearWater(root.Position) then
		resultEvent:FireClient(player, "far")
		return
	end
	fishing[player] = true
	resultEvent:FireClient(player, "cast")
	task.wait(random:NextNumber(MIN_WAIT, MAX_WAIT))
	-- Still holding the rod and still there after the wait?
	if player.Parent and rod.Parent == player.Character and fishing[player] then
		local fish = rollFish()
		addStat(player, "Fish", 1)
		addStat(player, "Coins", fish.coins)
		resultEvent:FireClient(player, "caught", fish.name, fish.coins)
	end
	fishing[player] = nil
end)

Players.PlayerAdded:Connect(function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, statName in { "Coins", "Fish" } do
		local stat = Instance.new("IntValue")
		stat.Name = statName
		stat.Parent = leaderstats
	end
	leaderstats.Parent = player
end)

Players.PlayerRemoving:Connect(function(player: Player)
	fishing[player] = nil
end)
