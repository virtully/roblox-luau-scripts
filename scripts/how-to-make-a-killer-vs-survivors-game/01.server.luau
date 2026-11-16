--!strict
-- How to make a killer vs survivors game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-killer-vs-survivors-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named KillerRound
-- Script in ServerScriptService named KillerRound.
-- Picks a killer with a chance that grows each round you are not picked, gives
-- survivors a head start, and ends when no survivor is left in the round.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local ROUND_SECONDS = 240
local HEAD_START = 15
local killerTeam = Teams:WaitForChild("Killer") :: Team
local survivorTeam = Teams:WaitForChild("Survivors") :: Team
local lobbyTeam = Teams:WaitForChild("Lobby") :: Team

local function chance(p: Player): number
	return tonumber(p:GetAttribute("KillerChance")) or 1
end

local function pickKiller(players: { Player }): Player
	local total = 0
	for _, p in players do
		total += chance(p)
	end
	local roll = math.random() * total
	for _, p in players do
		roll -= chance(p)
		if roll <= 0 then
			return p
		end
	end
	return players[#players]
end

local function playRound(players: { Player })
	workspace:SetAttribute("Escaped", 0)
	workspace:SetAttribute("ExitOpen", false)
	for _, gen in CollectionService:GetTagged("Generator") do
		gen:SetAttribute("Progress", 0)
	end
	local killer = pickKiller(players)
	for _, p in players do
		if p == killer then
			p:SetAttribute("KillerChance", 1)
			p.Team = lobbyTeam -- the killer waits in the lobby during the head start
		else
			p:SetAttribute("KillerChance", chance(p) + 1)
			p.Team = survivorTeam
			p:LoadCharacterAsync() -- spawns at the team's SpawnLocation
			local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					p.Team = lobbyTeam -- out of the round: respawns in the lobby to watch
				end)
			end
		end
	end
	workspace:SetAttribute("Status", "Hide! The killer arrives in " .. HEAD_START .. " seconds")
	task.wait(HEAD_START)
	killer.Team = killerTeam
	killer:LoadCharacterAsync()
	local endsAt = os.clock() + ROUND_SECONDS
	while os.clock() < endsAt and #survivorTeam:GetPlayers() > 0 and killer.Parent do
		workspace:SetAttribute("TimeLeft", math.ceil(endsAt - os.clock()))
		task.wait(1)
	end
	local escaped = tonumber(workspace:GetAttribute("Escaped")) or 0
	local survived = escaped + #survivorTeam:GetPlayers()
	workspace:SetAttribute("Status", if survived > 0 then survived .. " survived" else "The killer wins")
	for _, p in Players:GetPlayers() do
		p.Team = lobbyTeam
		p:LoadCharacterAsync()
	end
end

while true do
	task.wait(20) -- intermission
	local players = Players:GetPlayers()
	if #players >= 2 then
		playRound(players)
	end
end
