--!strict
-- How to make a settings menu in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-settings-menu
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SettingsSaver
-- Script in ServerScriptService named SettingsSaver.
-- Loads each player's settings into attributes on the player, and saves the changes
-- the settings menu sends. Only known settings with the right type are kept.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Every setting and its default. The menu shows these.
local DEFAULTS: { [string]: boolean } = {
	Music = true,
	SoundEffects = true,
	Shadows = true,
}

local store = DataStoreService:GetDataStore("PlayerSettings_v1")
local changeEvent = Instance.new("RemoteEvent")
changeEvent.Name = "ChangeSetting"
changeEvent.Parent = ReplicatedStorage

local dirty: { [Player]: boolean } = {} -- changed since the last save
local loaded: { [Player]: boolean } = {}

local function current(player: Player): { [string]: boolean }
	local values: { [string]: boolean } = {}
	for name, default in DEFAULTS do
		local value = player:GetAttribute("Setting_" .. name)
		values[name] = if type(value) == "boolean" then value else default
	end
	return values
end

Players.PlayerAdded:Connect(function(player: Player)
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	local saved = if ok and type(data) == "table" then data else {}
	for name, default in DEFAULTS do
		local value = saved[name]
		player:SetAttribute("Setting_" .. name, if type(value) == "boolean" then value else default)
	end
	-- Only save later if the load worked, so a failed load never overwrites good settings
	loaded[player] = ok
end)

changeEvent.OnServerEvent:Connect(function(player: Player, name: unknown, value: unknown)
	if typeof(name) ~= "string" or DEFAULTS[name] == nil or typeof(value) ~= "boolean" then
		return
	end
	player:SetAttribute("Setting_" .. name, value)
	dirty[player] = true
end)

local function save(player: Player)
	if not (dirty[player] and loaded[player]) then
		return
	end
	dirty[player] = nil
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), current(player))
	end)
	if not ok then
		warn("SettingsSaver: could not save", player.Name, err)
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	dirty[player] = nil
	loaded[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(3)
end)
