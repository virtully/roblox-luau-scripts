--!strict
-- How to make an admin panel in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-admin-panel-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named AdminServer
-- Script in ServerScriptService named AdminServer.
-- Ranks, server-side checks, kick, timed bans saved in a DataStore,
-- and MessagingService so a ban removes the player from every server at once.
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ranks by user ID. 1 = Moderator, 2 = Admin, 3 = Owner. Everyone else is 0.
local RANKS: { [number]: number } = {
	[123456] = 3,
}
local RANK_NAMES = { [0] = "Player", [1] = "Moderator", [2] = "Admin", [3] = "Owner" }
-- The lowest rank that may use each action
local MIN_RANK: { [string]: number } = {
	kick = 1,
	ban = 2,
	unban = 2,
}
-- Fixed reasons: the banned player sees one of these. Typed text shown to another
-- player would have to go through Roblox's text filter first, so the panel never sends any.
local REASONS = { "Exploiting", "Harassing players", "Spamming", "Breaking the game rules" }
local MAX_BAN_MINUTES = 60 * 24 * 365
local BAN_TOPIC = "AdminBans"
local bans = DataStoreService:GetDataStore("AdminBans_v1")

local remote = Instance.new("RemoteFunction")
remote.Name = "AdminRemote"
remote.Parent = ReplicatedStorage

local function rankOf(userId: number): number
	-- In a Studio playtest of a place you own yourself, you are the Owner
	if RunService:IsStudio() and game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId then
		return 3
	end
	return RANKS[userId] or 0
end

local function findPlayer(text: string): Player?
	local lower = string.lower(text)
	if lower == "" then
		return nil
	end
	for _, player in Players:GetPlayers() do
		if string.sub(string.lower(player.Name), 1, #lower) == lower
			or string.sub(string.lower(player.DisplayName), 1, #lower) == lower
		then
			return player
		end
	end
	return nil
end

local function banMessage(reason: string, untilTime: number): string
	if untilTime < 0 then
		return "You are banned: " .. reason
	end
	local minutes = math.max(1, math.ceil((untilTime - os.time()) / 60))
	return "You are banned for " .. minutes .. " more minutes: " .. reason
end

-- Returns the active ban for a user ID, if any
local function getBan(userId: number): (string?, number?)
	local ok, data = pcall(function()
		return bans:GetAsync(tostring(userId))
	end)
	if not ok or type(data) ~= "table" then
		return nil, nil
	end
	local untilTime = tonumber(data.untilTime) or 0
	if untilTime >= 0 and untilTime <= os.time() then
		return nil, nil -- it ran out
	end
	return tostring(data.reason or "No reason given"), untilTime
end

-- Every server listens for bans made on other servers
local subscribed, subscribeErr = pcall(function()
	MessagingService:SubscribeAsync(BAN_TOPIC, function(message)
		local data = message.Data
		if type(data) ~= "table" then
			return
		end
		local target = Players:GetPlayerByUserId(tonumber(data.userId) or 0)
		if target then
			target:Kick(banMessage(tostring(data.reason), tonumber(data.untilTime) or -1))
		end
	end)
end)
if not subscribed then
	warn("AdminServer: cross-server bans are off:", subscribeErr)
end

type Request = { action: string?, target: string?, reason: string?, minutes: number? }

local actions: { [string]: (caller: Player, request: Request) -> string } = {
	kick = function(caller, request)
		local target = findPlayer(request.target or "")
		if not target then
			return "No player in this server matches that name."
		end
		if rankOf(target.UserId) >= rankOf(caller.UserId) then
			return "You can only kick players below your rank."
		end
		target:Kick("Kicked by a moderator: " .. (request.reason or REASONS[#REASONS]))
		return "Kicked " .. target.Name .. "."
	end,
	ban = function(caller, request)
		-- the target can be a name in this server or a user ID for someone offline
		local target = findPlayer(request.target or "")
		local userId = if target then target.UserId else tonumber(request.target)
		if not userId then
			return "Type the name of a player in this server, or a user ID."
		end
		if rankOf(userId) >= rankOf(caller.UserId) then
			return "You can only ban players below your rank."
		end
		local minutes = math.floor(tonumber(request.minutes) or 0)
		local untilTime = if minutes > 0 then os.time() + math.min(minutes, MAX_BAN_MINUTES) * 60 else -1
		local reason = request.reason or REASONS[#REASONS]
		local ok, err = pcall(function()
			bans:SetAsync(tostring(userId), { untilTime = untilTime, reason = reason, by = caller.UserId })
		end)
		if not ok then
			return "The ban was not saved: " .. tostring(err)
		end
		if target then
			target:Kick(banMessage(reason, untilTime))
		end
		pcall(function()
			MessagingService:PublishAsync(BAN_TOPIC, { userId = userId, reason = reason, untilTime = untilTime })
		end)
		return "Banned " .. userId .. (if untilTime < 0 then " for good." else " for " .. minutes .. " minutes.")
	end,
	unban = function(_caller, request)
		local userId = tonumber(request.target)
		if not userId then
			return "Unban takes a user ID."
		end
		local ok, err = pcall(function()
			bans:RemoveAsync(tostring(userId))
		end)
		return if ok then "Unbanned " .. userId .. "." else "Unban failed: " .. tostring(err)
	end,
}

-- The only way in from clients. Every check happens here, never in the panel.
remote.OnServerInvoke = function(caller: Player, request: any): any
	local rank = rankOf(caller.UserId)
	if type(request) ~= "table" then
		-- the panel asks once on join: which rank am I, and which reasons can I pick
		return { rank = rank, rankName = RANK_NAMES[rank], reasons = if rank > 0 then REASONS else {} }
	end
	local action = request.action
	local handler = if type(action) == "string" then actions[action] else nil
	if not handler or type(action) ~= "string" then
		return { ok = false, message = "Unknown action." }
	end
	if rank < (MIN_RANK[action] or math.huge) then
		return { ok = false, message = "Your rank cannot do that." }
	end
	local clean: Request = {
		target = if type(request.target) == "string" then string.sub(request.target, 1, 40) else nil,
		reason = if table.find(REASONS, request.reason) then request.reason else nil,
		minutes = if type(request.minutes) == "number" then request.minutes else nil,
	}
	local message = handler(caller, clean)
	print(("[Admin] %s (%d) %s %s: %s"):format(caller.Name, caller.UserId, action, clean.target or "", message))
	return { ok = true, message = message }
end

-- Banned players are removed as soon as they join
Players.PlayerAdded:Connect(function(player: Player)
	local reason, untilTime = getBan(player.UserId)
	if reason and untilTime then
		player:Kick(banMessage(reason, untilTime))
	end
end)
