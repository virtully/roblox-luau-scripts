--!strict
-- How to make a codes system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-codes-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CodeService
-- Script in ServerScriptService named CodeService.
-- Players type a code; the server checks it, saves that it was used and gives the reward.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Code = { coins: number, expires: number? } -- expires: a Unix time, or nil for never
-- Codes are not case sensitive: write them here in capitals
local CODES: { [string]: Code } = {
	RELEASE = { coins = 100 },
	THANKYOU = { coins = 250, expires = 1798761600 }, -- 1 January 2027, 00:00 UTC
}
local TRIES_PER_MINUTE = 6 -- stops players from guessing codes quickly

local store = DataStoreService:GetDataStore("RedeemedCodes_v1")
local redeemFunction = Instance.new("RemoteFunction")
redeemFunction.Name = "RedeemCode"
redeemFunction.Parent = ReplicatedStorage

local used: { [Player]: { [string]: boolean } } = {} -- loaded on join
local tries: { [Player]: { number } } = {}
local busy: { [Player]: boolean } = {}

local function addCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok then
		used[player] = if type(data) == "table" then data else {}
	else
		warn("CodeService: could not load codes for", player.Name, data)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	used[player] = nil
	tries[player] = nil
	busy[player] = nil
end)

local function tooManyTries(player: Player): boolean
	local now = os.clock()
	local recent: { number } = {}
	local previous: { number } = tries[player] or {}
	for _, t in previous do
		if now - t < 60 then
			table.insert(recent, t)
		end
	end
	table.insert(recent, now)
	tries[player] = recent
	return #recent > TRIES_PER_MINUTE
end

redeemFunction.OnServerInvoke = function(player: Player, text: unknown): string
	if typeof(text) ~= "string" or #text > 30 then
		return "Invalid code"
	end
	local list = used[player]
	if not list then
		return "Your data is still loading, try again in a moment"
	end
	if busy[player] then
		return "One moment..."
	end
	if tooManyTries(player) then
		return "Too many tries, wait a minute"
	end
	local name = string.upper((string.gsub(text, "%s", "")))
	local code = CODES[name]
	if not code then
		return "Invalid code"
	end
	if code.expires and os.time() > code.expires then
		return "This code has expired"
	end
	if list[name] then
		return "You already used this code"
	end

	-- Save first, then reward: a code that failed to save is not given out
	busy[player] = true
	local alreadySaved = false
	local ok = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function(old: any)
			alreadySaved = false -- UpdateAsync can run this more than once: only the last run counts
			local saved = if type(old) == "table" then old else {}
			if saved[name] then
				alreadySaved = true -- used on another server since this one loaded
				return nil -- returning nil cancels the write
			end
			saved[name] = true
			return saved
		end)
	end)
	busy[player] = nil
	if not ok then
		return "Could not save, try again later"
	end
	list[name] = true
	if alreadySaved then
		return "You already used this code"
	end
	addCoins(player, code.coins)
	return string.format("Code redeemed! +%d coins", code.coins)
end
