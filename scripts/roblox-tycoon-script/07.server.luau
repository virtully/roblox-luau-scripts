--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Leaderstats
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Called inside each pcall below, so a place that is not published yet
-- (no data store access) still gets its Cash
local function cashStore(): DataStore
	return DataStoreService:GetDataStore("TycoonCash_v1")
end

-- Players whose Cash loaded. Anyone missing from here is never saved,
-- so a failed load cannot overwrite their real Cash with 0.
local loaded: { [Player]: boolean } = {}
local savesInProgress = 0

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats

	local ok, saved = pcall(function()
		return cashStore():GetAsync(keyFor(player))
	end)
	if player.Parent ~= Players then
		return -- they left while their Cash was loading
	end
	if ok then
		cash.Value = if typeof(saved) == "number" then math.floor(saved) else 0
		loaded[player] = true
	else
		warn(`Could not load Cash for {player.Name}: {saved}`)
	end
	leaderstats.Parent = player
end

local function save(player: Player)
	if not loaded[player] then
		return
	end
	loaded[player] = nil -- save once, whether leaving or shutdown comes first

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if not (cash and cash:IsA("IntValue")) then
		return
	end
	local amount = cash.Value

	savesInProgress += 1
	local ok, err = pcall(function()
		cashStore():SetAsync(keyFor(player), amount)
	end)
	savesInProgress -= 1
	if not ok then
		warn(`Could not save Cash for {player.Name}: {err}`)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(save)

-- When the server shuts down, save everyone still here and wait for every save to finish
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	while savesInProgress > 0 do
		task.wait()
	end
end)
