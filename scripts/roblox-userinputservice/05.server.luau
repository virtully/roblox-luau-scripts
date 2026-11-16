--!strict
-- How to detect key presses with UserInputService
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-userinputservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named AbilityServer
-- Script in ServerScriptService named AbilityServer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COOLDOWN_SECONDS = 3

local useAbilityRemote = ReplicatedStorage:WaitForChild("UseAbility") :: RemoteEvent
local lastUse: { [Player]: number } = {}

useAbilityRemote.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (lastUse[player] or 0) < COOLDOWN_SECONDS then
		return -- too soon: ignore
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	lastUse[player] = now
	print(player.Name, "used their ability")
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastUse[player] = nil
end)
