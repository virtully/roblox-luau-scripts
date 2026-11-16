--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named InventoryData
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

type InventoryApi = {
	load: (player: Player, saved: any) -> (),
	serialize: (player: Player) -> any,
	unload: (player: Player) -> (),
}
local InventoryService = require(ServerScriptService:WaitForChild("InventoryService")) :: InventoryApi

local STORE_NAME = "PlayerInventory_v1"
local LOAD_ATTEMPTS = 3
local AUTOSAVE_SECONDS = 180

-- Only players whose saved data loaded are ever saved. A failed load must
-- never be followed by a save, or the empty inventory replaces the real one.
local canSave: { [Player]: boolean } = {}
local activeSaves = 0

local function keyFor(player: Player): string
	return "User_" .. player.UserId
end

-- One failed request should not cost anyone their items, so retry a few times.
-- GetDataStore sits inside the pcall too, so a Studio session that cannot
-- reach data stores gets a warning instead of stopping this script.
local function loadSaved(player: Player): (boolean, any)
	for attempt = 1, LOAD_ATTEMPTS do
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME):GetAsync(keyFor(player))
		end)
		if ok then
			return true, result
		end
		warn(`Inventory load failed for {player.Name} (attempt {attempt}): {result}`)
		if attempt < LOAD_ATTEMPTS then
			task.wait(attempt * 2)
		end
	end
	return false, nil
end

local function onPlayerAdded(player: Player)
	local ok, saved = loadSaved(player)
	if player.Parent ~= Players then
		return -- they left while we were loading
	end
	if ok then
		InventoryService.load(player, saved) -- saved is nil for a new player
		canSave[player] = true
	elseif RunService:IsStudio() then
		-- Usually means Studio access to API services is off. Play with the
		-- starter items so you can test, but never save them.
		warn("Inventory not loaded: playing with starter items that will not be saved")
		InventoryService.load(player, nil)
	else
		player:Kick("Your inventory could not be loaded. Please rejoin in a minute.")
	end
end

local function save(player: Player)
	if not canSave[player] then
		return -- their data never loaded, so there is nothing safe to write
	end
	local data = InventoryService.serialize(player)
	if not data then
		return
	end
	activeSaves += 1
	local ok, err = pcall(function()
		DataStoreService:GetDataStore(STORE_NAME):SetAsync(keyFor(player), data, { player.UserId })
	end)
	activeSaves -= 1
	if not ok then
		warn(`Inventory save failed for {player.Name}: {err}`)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	canSave[player] = nil
	InventoryService.unload(player)
end)

-- When the server shuts down, save everyone still here, then wait for every
-- save in progress, including ones that PlayerRemoving started
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	while activeSaves > 0 do
		task.wait()
	end
end)

-- Save everyone every few minutes, so a server crash costs minutes, not a session
while true do
	task.wait(AUTOSAVE_SECONDS)
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
end
