--!strict
-- How to make chat commands in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-chat-commands
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ChatCommands
-- Script in ServerScriptService named ChatCommands.
-- /reset for everyone; /speed, /bring, /kick and /heal for admins. Admin rights are checked here, on the server.
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- Put your admins' UserIds here, for example [123456789] = true
local ADMIN_USER_IDS: { [number]: boolean } = {
	-- [123456789] = true,
}
local GROUP_ID = 0 -- your group's ID, or 0 for no group admins
local ADMIN_RANK = 200 -- group members at or above this rank are admins
local MAX_SPEED = 100

local replyEvent = ReplicatedStorage:WaitForChild("CommandReply") :: RemoteEvent

type Handler = (player: Player, args: { string }) -> ()
type CommandInfo = { alias: string, adminOnly: boolean, help: string }

local commandList: { CommandInfo } = {}
local adminCache: { [Player]: boolean } = {}

-- Sends a private line to one player's chat window (shown by the CommandReplies LocalScript)
local function reply(player: Player, text: string, isError: boolean?)
	replyEvent:FireClient(player, text, isError == true)
end

local function isAdmin(player: Player): boolean
	local cached = adminCache[player]
	if cached ~= nil then
		return cached
	end
	local result = ADMIN_USER_IDS[player.UserId] == true
	-- The owner of a place owned by a user is always an admin
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
		result = true
	end
	if not result and GROUP_ID ~= 0 then
		-- GetRolesInGroupAsync asks Roblox's servers, so it can fail; a failure means no admin rights
		local ok, info = pcall(function()
			return GroupService:GetRolesInGroupAsync(player.UserId, GROUP_ID)
		end)
		-- info.Roles lists every role the player holds in the group, each with a Rank from 0 to 255
		if ok and type(info) == "table" and type(info.Roles) == "table" then
			for _, role in info.Roles do
				if type(role) == "table" and type(role.Rank) == "number" and role.Rank >= ADMIN_RANK then
					result = true
				end
			end
		end
	end
	adminCache[player] = result
	return result
end

-- Finds one player by the start of their name or display name, ignoring capitals. "me" is the caller.
local function findPlayer(caller: Player, query: string?): Player?
	if not query then
		return nil
	end
	local lower = string.lower(query)
	if lower == "me" then
		return caller
	end
	for _, player in Players:GetPlayers() do
		local name = string.lower(player.Name)
		local display = string.lower(player.DisplayName)
		if string.sub(name, 1, #lower) == lower or string.sub(display, 1, #lower) == lower then
			return player
		end
	end
	return nil
end

local function addCommand(primary: string, secondary: string?, adminOnly: boolean, help: string, handler: Handler)
	local command = Instance.new("TextChatCommand")
	command.Name = "Custom" .. string.sub(primary, 2) .. "Command"
	command.PrimaryAlias = primary
	command.SecondaryAlias = secondary or ""
	command.AutocompleteVisible = not adminOnly -- keep admin commands out of everyone's suggestions
	command.Parent = TextChatService
	table.insert(commandList, { alias = primary, adminOnly = adminOnly, help = help })

	command.Triggered:Connect(function(source: TextSource, unfilteredText: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if not player then
			return
		end
		if adminOnly and not isAdmin(player) then
			reply(player, "You cannot use that command.", true)
			return
		end
		-- Split the message into words and drop the first one, which is the alias
		local args: { string } = {}
		for word in string.gmatch(unfilteredText, "%S+") do
			table.insert(args, word)
		end
		table.remove(args, 1)
		handler(player, args)
	end)
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

addCommand("/reset", "/re", false, "respawn your character", function(player: Player, _args: { string })
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.Health = 0
	end
end)

addCommand("/speed", nil, true, "/speed 32 sets your walk speed", function(player: Player, args: { string })
	local speed = tonumber(args[1])
	local humanoid = getHumanoid(player)
	if not speed or speed ~= speed or not humanoid then
		reply(player, "Use it like this: /speed 32", true)
		return
	end
	humanoid.WalkSpeed = math.clamp(speed, 0, MAX_SPEED)
	reply(player, "Walk speed set to " .. humanoid.WalkSpeed)
end)

addCommand("/bring", nil, true, "/bring name moves a player to you", function(player: Player, args: { string })
	local target = findPlayer(player, args[1])
	local myCharacter = player.Character
	local theirCharacter = target and target.Character
	if not (target and myCharacter and theirCharacter) then
		reply(player, "No player found with that name.", true)
		return
	end
	-- 4 studs in front of the admin
	theirCharacter:PivotTo(myCharacter:GetPivot() * CFrame.new(0, 0, -4))
	reply(player, "Brought " .. target.DisplayName)
end)

addCommand("/kick", nil, true, "/kick name removes a player", function(player: Player, args: { string })
	local target = findPlayer(player, args[1])
	if not target then
		reply(player, "No player found with that name.", true)
		return
	end
	if target == player or isAdmin(target) then
		reply(player, "You cannot kick yourself or another admin.", true)
		return
	end
	-- A fixed reason: text typed by one player is never shown to another without filtering
	target:Kick("You were removed by an admin.")
	reply(player, "Kicked " .. target.DisplayName)
end)

addCommand("/heal", nil, true, "/heal or /heal name restores full health", function(player: Player, args: { string })
	local target = if args[1] then findPlayer(player, args[1]) else player
	local humanoid = target and getHumanoid(target)
	if not (target and humanoid) then
		reply(player, "No player found with that name.", true)
		return
	end
	humanoid.Health = humanoid.MaxHealth
	reply(player, "Healed " .. target.DisplayName)
end)

addCommand("/cmds", nil, false, "lists the commands you can use", function(player: Player, _args: { string })
	local admin = isAdmin(player)
	for _, info in commandList do
		if admin or not info.adminOnly then
			reply(player, info.alias .. ": " .. info.help)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	adminCache[player] = nil
end)
