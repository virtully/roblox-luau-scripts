--!strict
-- How to make a racing game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-racing-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RaceTracker
-- Script in ServerScriptService named RaceTracker.
-- Counts checkpoints and laps on the server, in order, and records each finish time.
local Players = game:GetService("Players")

local LAPS = 3
local MIN_SPLIT = 1.5 -- seconds: a faster split between two checkpoints is ignored

local folder = workspace:WaitForChild("Checkpoints") :: Folder
local checkpoints: { BasePart } = {} -- parts named 1, 2, 3 ...; 1 is the start and finish line
for _, child in folder:GetChildren() do
	local index = tonumber(child.Name)
	if index and child:IsA("BasePart") then
		checkpoints[index] = child
	end
end

type Racer = { nextIndex: number, lap: number, lastTouch: number, finishedAt: number? }
local racers: { [Player]: Racer } = {}
local raceStart = os.clock()

-- A touch from the driver's character or from any part of the car they are driving
local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorWhichIsA("Model")
	if not model then
		return nil
	end
	local seat = model:FindFirstChildWhichIsA("VehicleSeat", true)
	local character = if seat and seat.Occupant then seat.Occupant.Parent else model
	return if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
end

local function onCheckpoint(index: number, hit: BasePart)
	local player = playerFromHit(hit)
	local racer = player and racers[player]
	if not player or not racer or racer.finishedAt or index ~= racer.nextIndex then
		return -- wrong checkpoint, or already finished
	end
	local now = os.clock()
	if now - racer.lastTouch < MIN_SPLIT then
		return -- too fast to be a real drive
	end
	racer.lastTouch = now
	if index == 1 then
		racer.lap += 1
		if racer.lap > LAPS then
			racer.finishedAt = now - raceStart
			player:SetAttribute("FinishTime", racer.finishedAt)
			return
		end
	end
	racer.nextIndex = index % #checkpoints + 1
	player:SetAttribute("Lap", racer.lap)
end

for index, part in checkpoints do
	part.Touched:Connect(function(hit)
		onCheckpoint(index, hit)
	end)
end

-- Call this when the countdown ends: everyone starts behind checkpoint 1 on lap 0
local function startRace()
	raceStart = os.clock()
	table.clear(racers)
	for _, player in Players:GetPlayers() do
		racers[player] = { nextIndex = 1, lap = 0, lastTouch = 0 }
	end
end
startRace()
Players.PlayerRemoving:Connect(function(player)
	racers[player] = nil
end)
