--!strict
-- How to make a leaderboard in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-leaderboard-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Leaderstats
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Called inside each pcall below, so a place that is not published yet
-- (no data store access) still gets its leaderboard
local function statsStore(): DataStore
	return DataStoreService:GetDataStore("PlayerStats_v1")
end

-- Players whose saved stats loaded. Anyone missing from here is never saved,
-- so a failed load cannot overwrite real progress with zeros.
local loaded: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = leaderstats

	local ok, data = pcall(function()
		return statsStore():GetAsync(keyFor(player))
	end)
	if ok then
		if type(data) == "table" then
			coins.Value = tonumber(data.Coins) or 0
			wins.Value = tonumber(data.Wins) or 0
		end
		loaded[player] = true
	else
		warn(`Could not load stats for {player.Name}: {data}`)
	end

	leaderstats.Parent = player
end

local function save(player: Player)
	if not loaded[player] then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if not (coins and coins:IsA("IntValue") and wins and wins:IsA("IntValue")) then
		return
	end
	local ok, err = pcall(function()
		statsStore():SetAsync(keyFor(player), { Coins = coins.Value, Wins = wins.Value })
	end)
	if not ok then
		warn(`Could not save stats for {player.Name}: {err}`)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	loaded[player] = nil
end)

-- When the server shuts down, save everyone before it closes
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
