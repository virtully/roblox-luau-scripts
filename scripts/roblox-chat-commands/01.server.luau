--!strict
-- How to make chat commands in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-chat-commands
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ResetCommand
-- Script in ServerScriptService named ResetCommand.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local resetCommand = Instance.new("TextChatCommand")
resetCommand.Name = "ResetCommand"
resetCommand.PrimaryAlias = "/reset"
resetCommand.SecondaryAlias = "/re"
resetCommand.Parent = TextChatService

resetCommand.Triggered:Connect(function(source: TextSource, _text: string)
	-- The TextSource is the sender. Its UserId leads to their Player.
	local player = Players:GetPlayerByUserId(source.UserId)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)
