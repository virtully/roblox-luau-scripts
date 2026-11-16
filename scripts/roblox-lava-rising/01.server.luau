--!strict
-- How to make a rising lava game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-lava-rising
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LavaRounds
-- Script in ServerScriptService named LavaRounds.
-- Rounds where lava climbs the map. Survivors at the end win.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RISE_STUDS = 80 -- how far the lava climbs in one round
local ROUND_SECONDS = 90 -- how long the climb takes
local MIN_PLAYERS = 1 -- players needed to start (use 2 or more in a live game)
local INTERMISSION_SECONDS = 15
local RESULTS_SECONDS = 5

local map = workspace:WaitForChild("LavaMap")
local lava = map:WaitForChild("Lava") :: BasePart
local mapSpawn = map:WaitForChild("MapSpawn") :: BasePart
local lobbySpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)

lava.Anchored = true
local lavaStart = lava.CFrame -- saved once: every round resets the lava to this

local inRound: { [Player]: boolean } = {}
local roundActive = false

local function setStatus(text: string)
	-- The RoundStatus LocalScript shows this on every screen
	ReplicatedStorage:SetAttribute("RoundStatus", text)
end

local function getLiveHumanoid(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if humanoid and root and humanoid.Health > 0 then
		return humanoid, root
	end
	return nil, nil
end

local function countAlive(): number
	local count = 0
	for _ in inRound do
		count += 1
	end
	return count
end

local function addWin(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins and wins:IsA("IntValue") then
		wins.Value += 1
	end
end

-- Every frame during a round: anyone inside the lava dies
RunService.Heartbeat:Connect(function()
	if not roundActive then
		return
	end
	local half = lava.Size / 2
	for player in inRound do
		local humanoid, root = getLiveHumanoid(player)
		if humanoid and root then
			local offset = lava.CFrame:PointToObjectSpace(root.Position)
			if math.abs(offset.X) <= half.X and math.abs(offset.Z) <= half.Z and offset.Y <= half.Y then
				humanoid.Health = 0 -- kills through a ForceField too
			end
		end
	end
end)

-- Wins on the player list
local function onPlayerAdded(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = leaderstats
	leaderstats.Parent = player
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player) -- players who joined while the script waited for the map
end

Players.PlayerRemoving:Connect(function(player: Player)
	inRound[player] = nil
end)

local function runRound()
	-- Reset the lava and send everyone to the map
	lava.CFrame = lavaStart
	table.clear(inRound)
	for index, player in Players:GetPlayers() do
		local humanoid = getLiveHumanoid(player)
		local character = player.Character
		if humanoid and character then
			-- Spread players out a little so they do not land inside each other
			local spread = Vector3.new((index % 4) * 3 - 4.5, 3, math.floor(index / 4) * 3)
			character:PivotTo(mapSpawn.CFrame + spread)
			inRound[player] = true
			humanoid.Died:Once(function()
				inRound[player] = nil
			end)
		end
	end

	local rise = TweenService:Create(lava, TweenInfo.new(ROUND_SECONDS, Enum.EasingStyle.Linear), {
		CFrame = lavaStart + Vector3.new(0, RISE_STUDS, 0),
	})
	rise:Play()
	roundActive = true

	local started = os.clock()
	while os.clock() - started < ROUND_SECONDS and countAlive() > 0 do
		local left = math.ceil(ROUND_SECONDS - (os.clock() - started))
		setStatus(string.format("The lava is rising! %d s left, %d alive", left, countAlive()))
		task.wait(0.25)
	end
	roundActive = false
	rise:Cancel()

	-- Results: survivors win and go back to the lobby
	local winners = {}
	for player in inRound do
		if getLiveHumanoid(player) then
			addWin(player)
			table.insert(winners, player.Name)
			local character = player.Character
			if character and lobbySpawn then
				character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 4, 0))
			end
		end
	end
	table.clear(inRound)
	setStatus(if #winners > 0 then "Survivors: " .. table.concat(winners, ", ") else "The lava got everyone!")
	task.wait(RESULTS_SECONDS)
	lava.CFrame = lavaStart
end

while true do
	while #Players:GetPlayers() < MIN_PLAYERS do
		setStatus(string.format("Waiting for %d players...", MIN_PLAYERS))
		task.wait(1)
	end
	for seconds = INTERMISSION_SECONDS, 1, -1 do
		setStatus(string.format("Next round in %d", seconds))
		task.wait(1)
	end
	runRound()
end
