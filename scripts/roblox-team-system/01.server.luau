--!strict
-- How to make teams in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-team-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TeamManager
-- Script in ServerScriptService named TeamManager.
-- Lets players pick a team from the Teams service, keeps teams even, and respawns
-- the player at their team's SpawnLocation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local MAX_DIFFERENCE = 1 -- a team may have at most this many more players than the smallest
local SWITCH_COOLDOWN = 5 -- seconds between team changes for one player

local chooseTeam = Instance.new("RemoteEvent")
chooseTeam.Name = "ChooseTeam"
chooseTeam.Parent = ReplicatedStorage

local lastSwitch: { [Player]: number } = {}

-- Only teams with AutoAssignable off are offered in the picker
local function pickableTeams(): { Team }
	local list: { Team } = {}
	for _, child in Teams:GetChildren() do
		if child:IsA("Team") and not child.AutoAssignable then
			table.insert(list, child)
		end
	end
	return list
end

local function wouldUnbalance(team: Team, player: Player): boolean
	local smallest = math.huge
	for _, other in pickableTeams() do
		local count = #other:GetPlayers()
		if other == player.Team then
			count -= 1 -- the player is leaving that team
		end
		smallest = math.min(smallest, count)
	end
	return #team:GetPlayers() + 1 - smallest > MAX_DIFFERENCE
end

chooseTeam.OnServerEvent:Connect(function(player: Player, teamName: unknown)
	if typeof(teamName) ~= "string" then
		return
	end
	local team = Teams:FindFirstChild(teamName)
	if not (team and team:IsA("Team")) or team.AutoAssignable or player.Team == team then
		return
	end
	local now = os.clock()
	if now - (lastSwitch[player] or -math.huge) < SWITCH_COOLDOWN then
		return
	end
	if wouldUnbalance(team, player) then
		return
	end
	lastSwitch[player] = now
	player.Team = team
	player.Neutral = false
	-- Respawn so the player appears at a SpawnLocation with their team's TeamColor
	player:LoadCharacterAsync()
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastSwitch[player] = nil
end)
