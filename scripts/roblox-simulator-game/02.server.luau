--!strict
-- How to make a simulator game on Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-simulator-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SimulatorService
-- Owns every number: clicks earn coins here, upgrades and rebirths are bought here,
-- and leaderstats only display the result.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- false: everyone starts fresh each visit. true: load and save with the PlayerData module
-- from the DataStore tutorial (add PowerLevel = 1 and Rebirths = 0 to its DEFAULTS first).
local SAVE_PROGRESS = false

type Config = {
	MAX_POWER_LEVEL: number,
	MAX_CLICKS_PER_SECOND: number,
	clickValue: (powerLevel: number, rebirths: number) -> number,
	upgradeCost: (powerLevel: number) -> number,
	rebirthCost: (rebirths: number) -> number,
}
local Config = require(ReplicatedStorage:WaitForChild("SimulatorConfig")) :: Config

type Stats = { Coins: number, PowerLevel: number, Rebirths: number }

local remotes = Instance.new("Folder")
remotes.Name = "SimulatorRemotes"
local clickEvent = Instance.new("RemoteEvent")
clickEvent.Name = "Click"
clickEvent.Parent = remotes
local buyUpgrade = Instance.new("RemoteFunction")
buyUpgrade.Name = "BuyUpgrade"
buyUpgrade.Parent = remotes
local rebirthRemote = Instance.new("RemoteFunction")
rebirthRemote.Name = "Rebirth"
rebirthRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

local playerStats: { [Player]: Stats } = {}
local windowStart: { [Player]: number } = {} -- when this player's current one-second window began
local clickCount: { [Player]: number } = {} -- clicks counted in that window

-- Copies the server's numbers to what players see: leaderstats and one attribute
local function refresh(player: Player)
	local data = playerStats[player]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not (data and leaderstats) then
		return
	end
	local coins = leaderstats:FindFirstChild("Coins")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if coins and coins:IsA("IntValue") then
		coins.Value = data.Coins
	end
	if rebirths and rebirths:IsA("IntValue") then
		rebirths.Value = data.Rebirths
	end
	player:SetAttribute("PowerLevel", data.PowerLevel)
end

-- Starts a player with the data passed in (fresh numbers, or a saved table)
local function setup(player: Player, data: Stats)
	playerStats[player] = data
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Coins", "Rebirths" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player
	refresh(player)
end

-- A click carries no numbers: the server works out what it is worth
clickEvent.OnServerEvent:Connect(function(player: Player)
	local data = playerStats[player]
	if not data then
		return
	end
	local now = os.clock()
	local start = windowStart[player]
	if not start or now - start >= 1 then
		windowStart[player] = now
		clickCount[player] = 0
	end
	local count = clickCount[player] or 0
	if count >= Config.MAX_CLICKS_PER_SECOND then
		return -- an auto-clicker or a script firing the remote in a loop
	end
	clickCount[player] = count + 1
	data.Coins += Config.clickValue(data.PowerLevel, data.Rebirths)
	refresh(player)
end)

buyUpgrade.OnServerInvoke = function(player: Player): (boolean, string)
	local data = playerStats[player]
	if not data then
		return false, "Your stats have not loaded yet."
	end
	if data.PowerLevel >= Config.MAX_POWER_LEVEL then
		return false, "Click Power is maxed out."
	end
	local cost = Config.upgradeCost(data.PowerLevel)
	if data.Coins < cost then
		return false, `You need {cost - data.Coins} more coins.`
	end
	data.Coins -= cost
	data.PowerLevel += 1
	refresh(player)
	return true, `Click Power is now level {data.PowerLevel}.`
end

rebirthRemote.OnServerInvoke = function(player: Player): (boolean, string)
	local data = playerStats[player]
	if not data then
		return false, "Your stats have not loaded yet."
	end
	local cost = Config.rebirthCost(data.Rebirths)
	if data.Coins < cost then
		return false, `You need {cost - data.Coins} more coins to rebirth.`
	end
	-- A rebirth trades coins and upgrades for a permanent multiplier
	data.Coins = 0
	data.PowerLevel = 1
	data.Rebirths += 1
	refresh(player)
	return true, `Rebirth {data.Rebirths}! Every click is now worth x{data.Rebirths + 1}.`
end

-- Starting numbers: fresh ones, or the table the PlayerData module loads and saves
if SAVE_PROGRESS then
	type PlayerDataModule = {
		Loaded: RBXScriptSignal,
		Get: (player: Player) -> any,
	}
	local PlayerData = require(ServerScriptService:WaitForChild("PlayerData")) :: PlayerDataModule
	local function onLoaded(player: Player)
		local data = PlayerData.Get(player)
		if not data or playerStats[player] then
			return
		end
		if type(data.Coins) ~= "number" or type(data.PowerLevel) ~= "number" or type(data.Rebirths) ~= "number" then
			warn("SimulatorService: add PowerLevel = 1 and Rebirths = 0 to DEFAULTS in the PlayerData module")
			return
		end
		setup(player, data) -- the same table PlayerData saves, so every change is saved
	end
	PlayerData.Loaded:Connect(onLoaded)
	for _, player in Players:GetPlayers() do
		onLoaded(player) -- anyone whose data loaded before this script started
	end
else
	local function onPlayerAdded(player: Player)
		setup(player, { Coins = 0, PowerLevel = 1, Rebirths = 0 })
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	playerStats[player] = nil
	windowStart[player] = nil
	clickCount[player] = nil
end)
