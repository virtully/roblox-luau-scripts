--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FinishAnnouncer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
local finishLine = workspace:WaitForChild("FinishLine") :: BasePart

local finished: { [Player]: boolean } = {}

finishLine.Touched:Connect(function(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or finished[player] then
		return -- not a player, or already announced
	end
	finished[player] = true

	-- Every connected client runs its OnClientEvent handler with this text
	notify:FireAllClients(`{player.DisplayName} reached the finish!`)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	finished[player] = nil
end)
