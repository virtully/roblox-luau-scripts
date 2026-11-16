--!strict
-- How to make a hide and seek game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-hide-and-seek-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named HideAndSeek
-- Script in ServerScriptService named HideAndSeek.
-- Picks a seeker fairly, runs hide and seek phases, and checks every tag on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local HIDE_TIME = 30
local SEEK_TIME = 180
local TAG_RANGE = 8 -- studs between the two characters

local tagEvent = ReplicatedStorage:WaitForChild("Tag") :: RemoteEvent
local seekers = Teams:WaitForChild("Seekers") :: Team
local hiders = Teams:WaitForChild("Hiders") :: Team
local mapSpawn = workspace:WaitForChild("Map"):WaitForChild("MapSpawn") :: BasePart

local roundsSinceSeeking: { [Player]: number } = {}
local seeking = false

local function setStatus(text: string, timeLeft: number)
	ReplicatedStorage:SetAttribute("Status", text)
	ReplicatedStorage:SetAttribute("TimeLeft", timeLeft)
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

local function pickSeeker(players: { Player }): Player
	local best = players[1]
	for _, player in players do
		if (roundsSinceSeeking[player] or 0) > (roundsSinceSeeking[best] or 0) then
			best = player
		end
	end
	return best
end

local function hidersLeft(): number
	return #hiders:GetPlayers()
end

tagEvent.OnServerEvent:Connect(function(seeker, target)
	if not seeking or seeker.Team ~= seekers then
		return
	end
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target.Team ~= hiders then
		return
	end
	local a = seeker.Character and seeker.Character:GetPivot().Position
	local b = target.Character and target.Character:GetPivot().Position
	if not a or not b or (a - b).Magnitude > TAG_RANGE then
		return -- too far away on the server: ignore
	end
	target.Team = seekers -- found: now helps seek
	local tags = seeker:GetAttribute("Tags")
	seeker:SetAttribute("Tags", (if typeof(tags) == "number" then tags else 0) + 1)
end)

while true do
	local players = Players:GetPlayers()
	if #players < 2 then
		setStatus("Waiting for players", 0)
		task.wait(2)
		continue
	end

	local seeker = pickSeeker(players)
	for _, player in players do
		roundsSinceSeeking[player] = (roundsSinceSeeking[player] or 0) + 1
		player.Neutral = false
		player.Team = if player == seeker then seekers else hiders
		local character = player.Character
		if character then
			character:PivotTo(mapSpawn.CFrame + Vector3.new(math.random(-6, 6), 4, math.random(-6, 6)))
		end
	end
	roundsSinceSeeking[seeker] = 0

	-- hiding phase: the seeker cannot move
	local seekerHumanoid = humanoidOf(seeker)
	if seekerHumanoid then
		seekerHumanoid.WalkSpeed = 0
	end
	seeker:SetAttribute("Blind", true) -- a LocalScript shows a black screen while this is true
	for t = HIDE_TIME, 1, -1 do
		setStatus("Hide!", t)
		task.wait(1)
	end
	seeker:SetAttribute("Blind", false)
	if seekerHumanoid then
		seekerHumanoid.WalkSpeed = 16
	end

	-- seeking phase
	seeking = true
	local t = SEEK_TIME
	while t > 0 and hidersLeft() > 0 do
		setStatus("Seek!", t)
		task.wait(1)
		t -= 1
	end
	seeking = false

	local winners = hiders:GetPlayers()
	setStatus(if #winners > 0 then `Hiders win ({#winners} left)` else "Seekers win", 0)
	for _, player in winners do
		local wins = player:GetAttribute("Wins")
		player:SetAttribute("Wins", (if typeof(wins) == "number" then wins else 0) + 1)
	end
	task.wait(5)
	for _, player in Players:GetPlayers() do
		player.Neutral = true -- off both teams until the next round
		task.spawn(player.LoadCharacterAsync, player) -- back to the lobby
	end
	task.wait(10)
end
