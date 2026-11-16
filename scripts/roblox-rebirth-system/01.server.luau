--!strict
-- How to make a rebirth system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-rebirth-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Rebirths
-- Script in ServerScriptService named Rebirths.
-- Owns Coins and Rebirths. Rebirth resets Coins for a permanent coin multiplier.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BASE_COST = 1000 -- coins for the first rebirth; each later one costs this much more
local MULTIPLIER_PER_REBIRTH = 0.5 -- 1 rebirth = 1.5x coins, 2 = 2x, and so on
local REBIRTH_COOLDOWN = 1 -- seconds between rebirths for one player
local STORE_NAME = "PlayerRebirths_v1"
local AUTOSAVE_SECONDS = 120

local loaded: { [Player]: boolean } = {}
local lastRebirth: { [Player]: number } = {}

local function store(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function costFor(rebirths: number): number
	return BASE_COST * (rebirths + 1)
end

local function multiplierFor(rebirths: number): number
	return 1 + rebirths * MULTIPLIER_PER_REBIRTH
end

local requestRebirth = Instance.new("RemoteFunction")
requestRebirth.Name = "RequestRebirth"
requestRebirth.Parent = ReplicatedStorage

local awardCoins = Instance.new("BindableEvent")
awardCoins.Name = "AwardCoins"
awardCoins.Parent = ServerStorage

local function getStats(player: Player): (IntValue?, IntValue?)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	if coins and coins:IsA("IntValue") and rebirths and rebirths:IsA("IntValue") then
		return coins, rebirths
	end
	return nil, nil
end

-- The button reads these two attributes to show the price and the multiplier
local function updateAttributes(player: Player, rebirths: number)
	player:SetAttribute("RebirthCost", costFor(rebirths))
	player:SetAttribute("CoinMultiplier", multiplierFor(rebirths))
end

-- Every coin reward in the game should come through here, so the multiplier applies
local function addCoins(player: Player, amount: number)
	local coins, rebirths = getStats(player)
	if not (coins and rebirths) then
		return
	end
	if amount ~= amount or amount <= 0 or amount == math.huge then
		return
	end
	coins.Value += math.floor(amount * multiplierFor(rebirths.Value))
end

local function tryRebirth(player: Player): (boolean, string)
	local coins, rebirths = getStats(player)
	if not (coins and rebirths) then
		return false, "Your data is still loading"
	end
	local now = os.clock()
	if now - (lastRebirth[player] or 0) < REBIRTH_COOLDOWN then
		return false, "Slow down"
	end
	lastRebirth[player] = now
	local cost = costFor(rebirths.Value)
	if coins.Value < cost then
		return false, "You need " .. cost .. " coins"
	end
	-- The reset: coins go back to 0, rebirths go up by one
	coins.Value = 0
	rebirths.Value += 1
	updateAttributes(player, rebirths.Value)
	return true, "Rebirth " .. rebirths.Value .. "! Coins now x" .. multiplierFor(rebirths.Value)
end

-- The client sends nothing: the server already knows every number it needs
requestRebirth.OnServerInvoke = function(player: Player): (boolean, string)
	return tryRebirth(player)
end

awardCoins.Event:Connect(function(player: unknown, amount: unknown)
	if typeof(player) == "Instance" and player:IsA("Player") and type(amount) == "number" then
		addCoins(player, amount)
	end
end)

local function onPlayerAdded(player: Player)
	local leaderstats: Instance
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		leaderstats = existing
	else
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"

	local ok, data = pcall(function()
		return store():GetAsync(keyFor(player))
	end)
	if ok then
		if type(data) == "table" then
			coins.Value = math.max(0, math.floor(tonumber(data.Coins) or 0))
			rebirths.Value = math.max(0, math.floor(tonumber(data.Rebirths) or 0))
		end
		loaded[player] = true
	else
		warn("Could not load rebirths for " .. player.Name .. ": " .. tostring(data))
	end

	coins.Parent = leaderstats
	rebirths.Parent = leaderstats
	updateAttributes(player, rebirths.Value)
end

local function save(player: Player)
	if not loaded[player] then
		return
	end
	local coins, rebirths = getStats(player)
	if not (coins and rebirths) then
		return
	end
	local ok, err = pcall(function()
		store():SetAsync(keyFor(player), { Coins = coins.Value, Rebirths = rebirths.Value }, { player.UserId })
	end)
	if not ok then
		warn("Could not save rebirths for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	loaded[player] = nil
	lastRebirth[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
