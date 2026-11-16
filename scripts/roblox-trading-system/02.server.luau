--!strict
-- How to make a trading system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-trading-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TradeService
-- Script in ServerScriptService named TradeService.
-- Two players offer items from their Items folders; when both press Ready the server
-- checks every item again and swaps them in one step. The client only asks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REQUEST_SECONDS = 15 -- how long a trade request stays open
local READY_DELAY = 3 -- seconds after the last offer change before Ready counts

local tradeEvent = Instance.new("RemoteEvent")
tradeEvent.Name = "Trade"
tradeEvent.Parent = ReplicatedStorage

type Offer = { [string]: number }
type Trade = {
	a: Player,
	b: Player,
	offers: { [Player]: Offer },
	ready: { [Player]: boolean },
	changedAt: number,
}

local trades: { [Player]: Trade } = {} -- each player in a trade points at it
local requests: { [Player]: { [Player]: number } } = {} -- requests[target][from] = time sent

-- Each player's items are IntValues in a folder named Items: the value is how many they own
local function getItems(player: Player): Folder?
	local items = player:FindFirstChild("Items")
	return if items and items:IsA("Folder") then items else nil
end

local function owned(player: Player, itemName: string): number
	local items = getItems(player)
	local item = items and items:FindFirstChild(itemName)
	return if item and item:IsA("IntValue") then item.Value else 0
end

local function otherOf(trade: Trade, player: Player): Player
	return if trade.a == player then trade.b else trade.a
end

-- Sends both players the current state of their trade
local function sync(trade: Trade)
	for _, player in { trade.a, trade.b } do
		local other = otherOf(trade, player)
		tradeEvent:FireClient(player, "update", {
			with = other.Name,
			mine = trade.offers[player],
			theirs = trade.offers[other],
			myReady = trade.ready[player] == true,
			theirReady = trade.ready[other] == true,
		})
	end
end

local function endTrade(trade: Trade, reason: string)
	for _, player in { trade.a, trade.b } do
		if trades[player] == trade then
			trades[player] = nil
			if player.Parent then
				tradeEvent:FireClient(player, "closed", reason)
			end
		end
	end
end

-- Moves the offered counts from one Items folder to another
local function moveItems(offer: Offer, fromItems: Folder, toItems: Folder)
	for itemName, count in offer do
		local source = fromItems:FindFirstChild(itemName)
		if source and source:IsA("IntValue") then
			source.Value -= count
		end
		local dest = toItems:FindFirstChild(itemName)
		if dest and dest:IsA("IntValue") then
			dest.Value += count
		else
			local newItem = Instance.new("IntValue")
			newItem.Name = itemName
			newItem.Value = count
			newItem.Parent = toItems
		end
	end
end

local function complete(trade: Trade)
	-- Check everything again at the last moment: nothing may have changed hands since
	for _, player in { trade.a, trade.b } do
		for itemName, count in trade.offers[player] do
			if owned(player, itemName) < count then
				endTrade(trade, "An item is no longer there. Trade cancelled.")
				return
			end
		end
	end
	local itemsA, itemsB = getItems(trade.a), getItems(trade.b)
	if not (itemsA and itemsB) then
		endTrade(trade, "Trade cancelled.")
		return
	end
	-- No waits from here to the end, so the swap happens all at once
	moveItems(trade.offers[trade.a], itemsA, itemsB)
	moveItems(trade.offers[trade.b], itemsB, itemsA)
	endTrade(trade, "Trade complete!")
end

local handlers: { [string]: (player: Player, arg1: unknown, arg2: unknown) -> () } = {}

handlers.request = function(player, targetName)
	local target = if typeof(targetName) == "string" then Players:FindFirstChild(targetName) else nil
	if not (target and target:IsA("Player")) or target == player or trades[player] or trades[target] then
		return
	end
	requests[target] = requests[target] or {}
	requests[target][player] = os.clock()
	tradeEvent:FireClient(target, "requested", player.Name)
end

handlers.accept = function(player, fromName)
	local found = if typeof(fromName) == "string" then Players:FindFirstChild(fromName) else nil
	if not (found and found:IsA("Player") and requests[player]) then
		return
	end
	local from: Player = found
	local sentAt = requests[player][from]
	if not sentAt or os.clock() - sentAt > REQUEST_SECONDS then
		return
	end
	requests[player][from] = nil
	if trades[player] or trades[from] then
		return
	end
	local trade: Trade = { a = from, b = player, offers = { [from] = {}, [player] = {} }, ready = {}, changedAt = os.clock() }
	trades[from] = trade
	trades[player] = trade
	sync(trade)
end

handlers.offer = function(player, itemName, count)
	local trade = trades[player]
	if not trade or typeof(itemName) ~= "string" or typeof(count) ~= "number" then
		return
	end
	-- Whole numbers from 0 up to what the player owns
	local wanted = math.clamp(math.floor(count), 0, owned(player, itemName))
	local offer = trade.offers[player]
	if wanted > 0 then
		offer[itemName] = wanted
	else
		offer[itemName] = nil
	end
	-- Any change un-readies both players, so nobody can swap an item after the other said yes
	trade.ready = {}
	trade.changedAt = os.clock()
	sync(trade)
end

handlers.ready = function(player)
	local trade = trades[player]
	if not trade or os.clock() - trade.changedAt < READY_DELAY then
		return
	end
	trade.ready[player] = true
	if trade.ready[trade.a] and trade.ready[trade.b] then
		complete(trade)
	else
		sync(trade)
	end
end

handlers.cancel = function(player)
	local trade = trades[player]
	if trade then
		endTrade(trade, player.Name .. " cancelled the trade.")
	end
end

tradeEvent.OnServerEvent:Connect(function(player: Player, action: unknown, arg1: unknown, arg2: unknown)
	local handler = if typeof(action) == "string" then handlers[action] else nil
	if handler then
		handler(player, arg1, arg2)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local trade = trades[player]
	if trade then
		endTrade(trade, player.Name .. " left the game.")
	end
	requests[player] = nil
	for _, list in requests do
		list[player] = nil
	end
end)
