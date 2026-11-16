--!strict
-- How to save player data in Roblox Studio with DataStores
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-datastore-tutorial
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named PlayerData
-- PlayerData: loads each player's data when they join, keeps it in memory,
-- and saves it on a timer, when they leave and when the server shuts down.
-- Other server scripts use PlayerData.Get(player) to read and change it.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local STORE_NAME = "PlayerData"
local SCHEMA_VERSION = 2 -- raise this when the shape of the data changes, and add a step to migrate()
local AUTOSAVE_SECONDS = 180
-- In Studio a failed call gives up at once, so testing without data store access is quick
local MAX_ATTEMPTS = if RunService:IsStudio() then 1 else 4
local FIRST_RETRY_SECONDS = 1 -- doubles after each failure: 1, 2, 4

export type Data = {
	SchemaVersion: number,
	Coins: number,
	Level: number,
	Inventory: { string },
}

-- What a brand new player starts with
local DEFAULTS: { [string]: any } = {
	Coins = 0,
	Level = 1,
	Inventory = {},
}

type Session = {
	key: string,
	userId: number,
	data: Data,
	canSave: boolean, -- false if the load failed: default data must never replace real progress
}

-- Called inside each pcall below, so a place that is not published yet
-- (no data store access) still loads players with default data
local function store(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end
local sessions: { [Player]: Session } = {}
local pendingSaves: { [string]: number } = {} -- saves still running, per key
local loadedEvent = Instance.new("BindableEvent")

local PlayerData = {}

-- Fires with the player once their data is ready. Call PlayerData.Get(player) for the table:
-- a table sent through a BindableEvent arrives as a copy, so changing it would change nothing.
PlayerData.Loaded = loadedEvent.Event

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in value do
		copy[key] = deepCopy(item)
	end
	return copy
end

local function defaultData(): Data
	local data = deepCopy(DEFAULTS) -- a fresh copy, so players never share one Inventory table
	data.SchemaVersion = SCHEMA_VERSION
	return data
end

-- Brings saved data up to the current schema. Returns nil if it cannot be used safely.
local function migrate(saved: any): Data?
	if type(saved) ~= "table" then
		return nil
	end
	local version = tonumber(saved.SchemaVersion) or 1
	if version > SCHEMA_VERSION then
		return nil -- saved by a newer version of the game: never load or overwrite it here
	end

	-- One step per schema change, oldest first
	if version < 2 then
		-- Example: version 1 called the currency Gold. Only copy it when Coins is missing,
		-- so older data that already has Coins but no SchemaVersion keeps its value.
		if saved.Coins == nil then
			saved.Coins = saved.Gold
		end
		saved.Gold = nil
	end

	-- Add fields created since this player last saved, and replace values of the wrong type
	for field, default in DEFAULTS do
		if type(saved[field]) ~= type(default) then
			saved[field] = deepCopy(default)
		end
	end
	saved.SchemaVersion = SCHEMA_VERSION
	return saved
end

-- Runs a data store call in pcall. On failure it waits and tries again, doubling the
-- wait each time and adding a little randomness so servers do not all retry together.
local function withRetries(label: string, call: () -> any): (boolean, any)
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(call)
		if ok then
			return true, result
		end
		warn(`{label} failed (attempt {attempt} of {MAX_ATTEMPTS}): {result}`)
		if attempt < MAX_ATTEMPTS then
			local waitTime = FIRST_RETRY_SECONDS * 2 ^ (attempt - 1)
			task.wait(waitTime + math.random() * waitTime / 2)
		end
	end
	return false, nil
end

local function save(session: Session): boolean
	if not session.canSave then
		return false
	end
	local key = session.key
	pendingSaves[key] = (pendingSaves[key] or 0) + 1

	local newerSchema = false
	local ok = withRetries(`Save {key}`, function()
		return store():UpdateAsync(key, function(current: any)
			if type(current) == "table" and (tonumber(current.SchemaVersion) or 1) > SCHEMA_VERSION then
				newerSchema = true
				return nil -- returning nil cancels the write
			end
			-- Write the whole current table, tagged with the player's UserId
			return session.data, { session.userId }
		end)
	end)

	local left = (pendingSaves[key] or 1) - 1
	if left > 0 then
		pendingSaves[key] = left
	else
		pendingSaves[key] = nil
	end
	if newerSchema then
		session.canSave = false
		warn(`{key} was saved by a newer version of the game, so this server stopped saving it`)
	end
	return ok and not newerSchema
end

local function startAutosave(player: Player, session: Session)
	task.spawn(function()
		-- Start at a random point in the interval so servers do not all save at once
		task.wait(math.random() * AUTOSAVE_SECONDS)
		while sessions[player] == session do
			save(session)
			task.wait(AUTOSAVE_SECONDS)
		end
	end)
end

local function load(player: Player)
	local key = "User_" .. player.UserId

	-- If this player just left this server and came back, let the last save finish first
	while pendingSaves[key] do
		task.wait()
	end

	local ok, saved = withRetries(`Load {key}`, function()
		return store():GetAsync(key)
	end)
	if player.Parent ~= Players then
		return -- left while loading: nothing has changed, so there is nothing to save
	end

	local data: Data? = nil
	if ok then
		data = if saved == nil then defaultData() else migrate(saved)
	end

	local session: Session = {
		key = key,
		userId = player.UserId,
		data = data or defaultData(),
		canSave = data ~= nil,
	}
	if not session.canSave then
		warn(`Could not load {key}. {player.Name} is playing on default data that will not be saved.`)
	end

	sessions[player] = session
	player:SetAttribute("DataLoaded", session.canSave) -- a GUI can read this and warn the player
	startAutosave(player, session)
	loadedEvent:Fire(player)
end

local function endSession(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil -- stops the autosave loop and makes a second call do nothing
	save(session)
end

-- The player's live data table, or nil until it has loaded. Change it from server scripts only.
function PlayerData.Get(player: Player): Data?
	local session = sessions[player]
	return if session then session.data else nil
end

-- True when the player's data loaded and will be saved. Check it before selling anything.
function PlayerData.CanSave(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.canSave
end

-- Saves now instead of waiting for the timer, for moments that matter such as a purchase.
-- Yields, and returns true once the save has gone through.
function PlayerData.SaveNow(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and save(session)
end

Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(endSession)
for _, player in Players:GetPlayers() do
	task.spawn(load, player) -- players who joined before this module was first required
end

game:BindToClose(function()
	-- The server gives these functions 30 seconds, so save everyone at the same time
	for player in sessions do
		task.spawn(endSession, player)
	end
	-- Then wait for every save still running, including ones PlayerRemoving started
	while next(pendingSaves) do
		task.wait()
	end
end)

return PlayerData
