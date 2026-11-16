--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named WelcomeServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent

local function welcome(player: Player)
	-- The first argument picks which client receives it. Nobody else sees this.
	notify:FireClient(player, `Welcome, {player.DisplayName}! Press Q to change colour.`)
end

Players.PlayerAdded:Connect(welcome)

-- In Studio you can join before this script connects, so greet anyone already here
for _, player in Players:GetPlayers() do
	welcome(player)
end
