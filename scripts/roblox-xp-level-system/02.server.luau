--!strict
-- How to make an XP and level system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-xp-level-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named XpLevels
-- Script in ServerScriptService named XpLevels.
-- Level and XP on leaderstats, a level-up formula, XP from other server scripts, saved in a data store.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local BASE_XP = 100 -- XP from level 1 to level 2
local GROWTH = 1.5 -- how fast each level gets more expensive
local MAX_LEVEL = 100
local STORE_NAME = "PlayerLevels_v1"
local AUTOSAVE_SECONDS = 120

type LevelData = { Level: number, Xp: number }

-- Players whose saved data loaded. Anyone missing is never saved, so a failed load
-- cannot overwrite real progress with level 1.
local loaded: { [Player]: boolean } = {}

local function levelStore(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function xpForLevel(level: number): number
	return math.floor(BASE_XP * level ^ GROWTH)
end

-- Other server scripts give XP with: ServerStorage.AwardXp:Fire(player, 25)
local awardXp: BindableEvent
local existingEvent = ServerStorage:FindFirstChild("AwardXp")
if existingEvent and existingEvent:IsA("BindableEvent") then
	awardXp = existingEvent
else
	awardXp = Instance.new("BindableEvent")
	awardXp.Name = "AwardXp"
	awardXp.Parent = ServerStorage
end

local function getStats(player: Player): (IntValue?, IntValue?)
	local leaderstats = player:FindFirstChild("leaderstats")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	if level and level:IsA("IntValue") and xp and xp:IsA("IntValue") then
		return level, xp
	end
	return nil, nil
end

-- The XP bar reads this attribute so it knows how full to draw itself
local function updateNeeded(player: Player, level: number)
	player:SetAttribute("XpNeeded", if level >= MAX_LEVEL then 0 else xpForLevel(level))
end

local function addXp(player: Player, amount: number)
	local level, xp = getStats(player)
	if not (level and xp) then
		return
	end
	-- Only whole, positive, real numbers: NaN and infinity fail these checks
	if amount ~= amount or amount <= 0 or amount == math.huge then
		return
	end
	if level.Value >= MAX_LEVEL then
		return
	end
	local total = xp.Value + math.floor(amount)
	local newLevel = level.Value
	-- A loop, because one big reward can be worth several levels
	while newLevel < MAX_LEVEL and total >= xpForLevel(newLevel) do
		total -= xpForLevel(newLevel)
		newLevel += 1
	end
	if newLevel >= MAX_LEVEL then
		total = 0
	end
	if newLevel > level.Value then
		print(player.Name .. " reached level " .. newLevel)
	end
	level.Value = newLevel
	xp.Value = total
	updateNeeded(player, newLevel)
end

local function onPlayerAdded(player: Player)
	-- Reuse the folder if another script (coins, say) already made it
	local leaderstats: Instance
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		leaderstats = existing
	else
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local ok, data = pcall(function()
		return levelStore():GetAsync(keyFor(player))
	end)

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0

	if ok then
		if type(data) == "table" then
			level.Value = math.clamp(math.floor(tonumber(data.Level) or 1), 1, MAX_LEVEL)
			xp.Value = math.max(0, math.floor(tonumber(data.Xp) or 0))
		end
		loaded[player] = true
	else
		warn("Could not load levels for " .. player.Name .. ": " .. tostring(data))
	end

	level.Parent = leaderstats
	xp.Parent = leaderstats
	updateNeeded(player, level.Value)
end

local function save(player: Player)
	if not loaded[player] then
		return
	end
	local level, xp = getStats(player)
	if not (level and xp) then
		return
	end
	local data: LevelData = { Level = level.Value, Xp = xp.Value }
	local ok, err = pcall(function()
		levelStore():SetAsync(keyFor(player), data, { player.UserId })
	end)
	if not ok then
		warn("Could not save levels for " .. player.Name .. ": " .. tostring(err))
	end
end

awardXp.Event:Connect(function(player: unknown, amount: unknown)
	if typeof(player) == "Instance" and player:IsA("Player") and type(amount) == "number" then
		addXp(player, amount)
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	loaded[player] = nil
end)

-- Save everyone every few minutes, so a server crash loses little
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
	end
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
