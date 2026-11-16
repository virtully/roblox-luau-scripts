--!strict
-- How to make an RNG game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-rng-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RollServer
-- Script in ServerScriptService named RollServer.
-- Players ask to roll; the server picks the aura, keeps the cooldown and announces rare finds.
local MessagingService = game:GetService("MessagingService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type AurasModule = { roll: (Random, number) -> string, odds: (number) -> { [string]: number } }
local Auras = require(ReplicatedStorage:WaitForChild("Auras")) :: AurasModule

local ROLL_COOLDOWN = 1 -- seconds between rolls
local ANNOUNCE_BELOW = 1 -- auras under 1% chance are announced to every server
local TOPIC = "RareRoll"

local function remote(name: string): RemoteFunction
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local rng = Random.new()
local lastRoll: { [Player]: number } = {}

remote("Roll").OnServerInvoke = function(player: Player)
	local now = os.clock()
	if now - (lastRoll[player] or 0) < ROLL_COOLDOWN then
		return nil
	end
	lastRoll[player] = now
	-- Luck is an attribute only server scripts set, from earned boosts or a paid potion
	local luck = math.max(1, tonumber(player:GetAttribute("Luck")) or 1)
	local aura = Auras.roll(rng, luck)
	if Auras.odds(luck)[aura] < ANNOUNCE_BELOW then
		pcall(function()
			MessagingService:PublishAsync(TOPIC, player.DisplayName .. " rolled " .. aura .. "!")
		end)
	end
	return aura
end

-- The shop asks before it shows a paid luck potion. false: hide it and offer an earnable boost.
remote("CanBuyLuck").OnServerInvoke = function(player: Player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	return ok and info.ArePaidRandomItemsRestricted == false
end

pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(message)
		print(message.Data) -- replace with a banner on every client
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)
