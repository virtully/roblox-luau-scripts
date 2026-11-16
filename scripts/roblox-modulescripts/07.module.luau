--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named CoinService
-- ModuleScript in ServerScriptService named CoinService.
-- The one place that changes coins. Server Scripts call get, add and spend.
local Players = game:GetService("Players")

local STARTING_COINS = 50

local coins: { [Player]: number } = {}
local labels: { [Player]: IntValue } = {}

local CoinService = {}

function CoinService.get(player: Player): number
	return coins[player] or 0
end

function CoinService.add(player: Player, amount: number)
	if amount <= 0 or not coins[player] then
		return
	end
	coins[player] += amount
	labels[player].Value = coins[player]
end

-- Returns true and takes the coins if the player can afford it; otherwise changes nothing
function CoinService.spend(player: Player, amount: number): boolean
	local balance = coins[player]
	if not balance or amount <= 0 or balance < amount then
		return false
	end
	coins[player] = balance - amount
	labels[player].Value = coins[player]
	return true
end

-- This code runs once, the first time any Script requires CoinService
local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local label = Instance.new("IntValue")
	label.Name = "Coins"
	label.Value = STARTING_COINS
	label.Parent = leaderstats
	leaderstats.Parent = player
	coins[player] = STARTING_COINS
	labels[player] = label
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player: Player)
	coins[player] = nil
	labels[player] = nil
end)

return CoinService
