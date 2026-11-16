--!strict
-- How to add chat tags in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-chat-tags
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ChatTags
-- LocalScript in StarterPlayerScripts named ChatTags.
-- Adds each sender's tag and name colour (set by ChatTagService) to their chat messages.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local function colorTag(text: string, color: Color3): string
	-- Rich text: <font color="#RRGGBB">text</font>
	return string.format('<font color="#%s">%s</font>', color:ToHex(), text)
end

-- Set this callback only once in the whole game: a second script setting it replaces this one
TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	if not source then
		return nil -- a system message, not from a player
	end
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player then
		return nil
	end

	local tag = player:GetAttribute("ChatTag")
	local tagColor = player:GetAttribute("ChatTagColor")
	local nameColor = player:GetAttribute("NameColor")
	if type(tag) ~= "string" then
		return nil -- no tag: leave the message as Roblox draws it
	end

	local name = message.PrefixText
	if typeof(nameColor) == "Color3" then
		name = colorTag(name, nameColor)
	end
	local label = "[" .. tag .. "]"
	if typeof(tagColor) == "Color3" then
		label = colorTag(label, tagColor)
	end

	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = label .. " " .. name
	return properties
end
