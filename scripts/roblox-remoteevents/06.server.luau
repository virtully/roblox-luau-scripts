--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RedeemServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local redeemCode = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RedeemCode") :: RemoteFunction

-- Codes live on the server, where no player can read them
local CODES: { [string]: number } = {
	LAUNCH = 100,
	THANKYOU = 50,
}
local MAX_LENGTH = 20
local COOLDOWN_SECONDS = 2

local usedCodes: { [Player]: { [string]: boolean } } = {}
local lastTry: { [Player]: number } = {}

-- Assign with =. OnServerInvoke is a callback, not an event you Connect to.
redeemCode.OnServerInvoke = function(player: Player, code: unknown): (boolean, string)
	local now = os.clock()
	local last = lastTry[player]
	if last and now - last < COOLDOWN_SECONDS then
		return false, "Wait a moment before trying again"
	end
	lastTry[player] = now

	if type(code) ~= "string" or #code == 0 or #code > MAX_LENGTH then
		return false, "Type a code first"
	end

	local key = string.upper(code)
	local reward = CODES[key]
	if not reward then
		return false, "That code doesn't exist"
	end

	local used = usedCodes[player]
	if not used then
		used = {}
		usedCodes[player] = used
	end
	if used[key] then
		return false, "You already used that code"
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not (coins and coins:IsA("IntValue")) then
		return false, "Coins aren't set up in this game yet"
	end

	used[key] = true
	coins.Value += reward
	return true, `Code accepted: +{reward} coins`
end

Players.PlayerRemoving:Connect(function(player: Player)
	usedCodes[player] = nil
	lastTry[player] = nil
end)
