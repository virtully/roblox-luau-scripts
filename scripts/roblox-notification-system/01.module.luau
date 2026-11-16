--!strict
-- How to make a notification system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-notification-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Notifications
-- ModuleScript in ServerScriptService named Notifications.
-- Server scripts call Notifications.send(player, text, kind) or Notifications.sendAll(text, kind).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notifyEvent = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent

local MAX_LENGTH = 120 -- longer messages are cut, so a mistake cannot fill the screen

export type Kind = "info" | "success" | "error"

local function clean(text: string): string
	if #text > MAX_LENGTH then
		return string.sub(text, 1, MAX_LENGTH - 3) .. "..."
	end
	return text
end

local Notifications = {}

-- One player
function Notifications.send(player: Player, text: string, kind: Kind?)
	notifyEvent:FireClient(player, clean(text), kind or "info")
end

-- Everyone in the server
function Notifications.sendAll(text: string, kind: Kind?)
	notifyEvent:FireAllClients(clean(text), kind or "info")
end

return Notifications
