--!strict
-- How to make chat commands in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-chat-commands
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CommandReplies
-- LocalScript in StarterPlayerScripts named CommandReplies.
-- Shows the server's replies to chat commands as system lines that only this player sees.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local replyEvent = ReplicatedStorage:WaitForChild("CommandReply") :: RemoteEvent
local systemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem") :: TextChannel

replyEvent.OnClientEvent:Connect(function(text: unknown, isError: unknown)
	if typeof(text) ~= "string" then
		return
	end
	-- The default RBXSystem channel colours a message red when its metadata contains "Error"
	systemChannel:DisplaySystemMessage(text, if isError == true then "Error" else "Info")
end)
