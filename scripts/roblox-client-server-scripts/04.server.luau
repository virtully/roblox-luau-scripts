--!strict
-- LocalScript vs Script vs ModuleScript in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-client-server-scripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RewardServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Describes what RewardSettings returns, for Luau's type checker
type Settings = { AMOUNT: number, COOLDOWN: number }
local RewardSettings = require(ReplicatedStorage:WaitForChild("RewardSettings")) :: Settings

-- The server creates the RemoteEvent, so it exists before any client looks for it
local claimReward = Instance.new("RemoteEvent")
claimReward.Name = "ClaimReward"
claimReward.Parent = ReplicatedStorage

local lastClaim: { [Player]: number } = {}

local function onPlayerAdded(player: Player)
	player:SetAttribute("Coins", 0) -- attributes set by the server replicate to clients
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Roblox passes the player who fired the event. Anything else a client sends is
-- ignored: the server decides the amount and the timing.
claimReward.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	local last = lastClaim[player]
	if last and now - last < RewardSettings.COOLDOWN then
		return -- too soon, ignore the request
	end
	lastClaim[player] = now

	local coins = player:GetAttribute("Coins")
	if type(coins) == "number" then
		player:SetAttribute("Coins", coins + RewardSettings.AMOUNT)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastClaim[player] = nil
end)
