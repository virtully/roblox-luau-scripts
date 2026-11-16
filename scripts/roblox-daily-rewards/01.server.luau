--!strict
-- How to make daily rewards in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-daily-rewards
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DailyRewards
-- Script in ServerScriptService named DailyRewards.
-- One reward every 24 hours. Claiming again within 48 hours keeps the streak going
-- and the rewards grow each day for a week, then the week starts over.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REWARDS = { 50, 75, 100, 150, 200, 300, 500 } -- coins for day 1 to day 7 of a streak
local CLAIM_EVERY = 24 * 60 * 60 -- seconds between claims
local STREAK_LOST_AFTER = 48 * 60 * 60 -- miss a whole day and the streak starts over

type Record = { last: number, streak: number }

local store = DataStoreService:GetDataStore("DailyRewards_v1")
local statusFunction = Instance.new("RemoteFunction")
statusFunction.Name = "GetDailyStatus"
statusFunction.Parent = ReplicatedStorage
local claimFunction = Instance.new("RemoteFunction")
claimFunction.Name = "ClaimDaily"
claimFunction.Parent = ReplicatedStorage

local records: { [Player]: Record } = {}
local claiming: { [Player]: boolean } = {}

local function readRecord(data: any): Record
	if type(data) == "table" and type(data.last) == "number" and type(data.streak) == "number" then
		return { last = data.last, streak = data.streak }
	end
	return { last = 0, streak = 0 }
end

-- The streak day the next claim will be, from 1 to 7
local function nextDay(record: Record, now: number): number
	if now - record.last >= STREAK_LOST_AFTER then
		return 1
	end
	return record.streak % #REWARDS + 1
end

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
		records[player] = readRecord(data)
	else
		warn("DailyRewards: could not load", player.Name, data)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	records[player] = nil
	claiming[player] = nil
end)

-- What the menu shows: seconds until the next claim (0 = ready now) and which day it is
statusFunction.OnServerInvoke = function(player: Player)
	local record = records[player]
	if not record then
		return nil
	end
	local now = os.time()
	return {
		wait = math.max(0, record.last + CLAIM_EVERY - now),
		day = nextDay(record, now),
		rewards = REWARDS,
	}
end

claimFunction.OnServerInvoke = function(player: Player): string
	local record = records[player]
	if not record then
		return "Still loading, try again in a moment"
	end
	if claiming[player] then
		return "One moment..."
	end
	claiming[player] = true
	local now = os.time()
	local claimedDay: number? = nil
	-- UpdateAsync reads the newest saved record and decides inside the update, so a
	-- second server (or a second click) cannot claim the same day twice
	local ok, err = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function(old: any)
			-- UpdateAsync can run this more than once: only the last run counts
			claimedDay = nil
			local saved = readRecord(old)
			if now - saved.last < CLAIM_EVERY then
				return nil -- not ready: returning nil cancels the save
			end
			local day = nextDay(saved, now)
			claimedDay = day
			return { last = now, streak = day }
		end)
	end)
	claiming[player] = nil
	if not ok then
		warn("DailyRewards: could not save", player.Name, err)
		return "Could not save, try again later"
	end
	local day = claimedDay
	if not day then
		return "Come back later for your next reward"
	end
	records[player] = { last = now, streak = day }
	addCoins(player, REWARDS[day])
	return string.format("Day %d reward: +%d coins!", day, REWARDS[day])
end
