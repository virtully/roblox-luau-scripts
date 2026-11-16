--!strict
-- How to make admin commands in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-admin-commands
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named AdminCommands
-- Script in ServerScriptService named AdminCommands.
-- Chat commands for the user IDs in ADMINS: /kick, /tp, /speed, /heal, /kill.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

-- Your user ID is the number in your profile link: roblox.com/users/123456/profile
local ADMINS: { [number]: boolean } = {
	[123456] = true,
}

local function isAdmin(userId: number): boolean
	-- In a Studio playtest of a place you own yourself, you count as an admin too
	local ownerInStudio = RunService:IsStudio() and game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId
	return ADMINS[userId] == true or ownerInStudio
end

-- Finds players by the start of their name or display name, or "me", "all", "others"
local function findPlayers(text: string?, caller: Player): { Player }
	local found: { Player } = {}
	if not text or text == "" or text == "me" then
		table.insert(found, caller)
		return found
	end
	local lower = string.lower(text)
	for _, player in Players:GetPlayers() do
		local name = string.lower(player.Name)
		local display = string.lower(player.DisplayName)
		if lower == "all"
			or (lower == "others" and player ~= caller)
			or string.sub(name, 1, #lower) == lower
			or string.sub(display, 1, #lower) == lower
		then
			table.insert(found, player)
		end
	end
	return found
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

type Handler = (caller: Player, args: { string }) -> ()

local commands: { [string]: Handler } = {
	kick = function(caller, args)
		for _, target in findPlayers(args[2], caller) do
			if target ~= caller then
				target:Kick("Kicked by an admin")
			end
		end
	end,
	tp = function(caller, args)
		-- /tp name: go to them. /tp name1 name2: send name1 to name2.
		local destination = if args[3] then findPlayers(args[3], caller)[1] else findPlayers(args[2], caller)[1]
		local movers: { Player } = if args[3] then findPlayers(args[2], caller) else { caller }
		local destCharacter = destination and destination.Character
		if not destCharacter then
			return
		end
		for _, mover in movers do
			local character = mover.Character
			if character and mover ~= destination then
				character:PivotTo(destCharacter:GetPivot() * CFrame.new(0, 0, 4))
			end
		end
	end,
	speed = function(caller, args)
		-- /speed name 50
		local speed = tonumber(args[3]) or 16
		for _, target in findPlayers(args[2], caller) do
			local humanoid = getHumanoid(target)
			if humanoid then
				humanoid.WalkSpeed = math.clamp(speed, 0, 200)
			end
		end
	end,
	heal = function(caller, args)
		for _, target in findPlayers(args[2], caller) do
			local humanoid = getHumanoid(target)
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end,
	kill = function(caller, args)
		for _, target in findPlayers(args[2], caller) do
			local humanoid = getHumanoid(target)
			if humanoid then
				humanoid.Health = 0
			end
		end
	end,
}

-- Creates one TextChatCommand per command. Only admins get a result; for everyone
-- else the command does nothing, and the message is not shown in chat either.
for name, handler in commands do
	local command = Instance.new("TextChatCommand")
	command.Name = "Admin_" .. name
	command.PrimaryAlias = "/" .. name
	command.AutocompleteVisible = false -- keep the commands out of everyone's suggestions
	command.Parent = TextChatService
	command.Triggered:Connect(function(textSource: TextSource, unfilteredText: string)
		local caller = Players:GetPlayerByUserId(textSource.UserId)
		if not caller or not isAdmin(caller.UserId) then
			return
		end
		handler(caller, string.split(unfilteredText, " "))
	end)
end
