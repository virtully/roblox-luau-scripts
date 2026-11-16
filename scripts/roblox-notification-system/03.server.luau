--!strict
-- How to make a notification system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-notification-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named WelcomeNotices
-- Script in ServerScriptService named WelcomeNotices.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

type NotificationsModule = {
	send: (player: Player, text: string, kind: ("info" | "success" | "error")?) -> (),
	sendAll: (text: string, kind: ("info" | "success" | "error")?) -> (),
}
local Notifications = require(ServerScriptService:WaitForChild("Notifications")) :: NotificationsModule

Players.PlayerAdded:Connect(function(player: Player)
	Notifications.send(player, "Welcome! Collect coins to unlock new areas.", "info")
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Notifications.send(other, player.DisplayName .. " joined the game", "success")
		end
	end
end)
