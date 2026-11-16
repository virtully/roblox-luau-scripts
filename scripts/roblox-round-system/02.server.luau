--!strict
-- How to make a round system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-round-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RoundSystem
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Settings
local MIN_PLAYERS = 2 -- set to 1 while you test alone
local INTERMISSION_SECONDS = 20
local GET_READY_SECONDS = 5
local ROUND_SECONDS = 120
local RESULTS_SECONDS = 5
local USE_TEAMS = false -- true: the round ends when only one team has players left

local mapsFolder = ServerStorage:WaitForChild("Maps")
local random = Random.new()

-- What every player's screen shows lives in attributes on this folder.
-- Attributes set by the server replicate to all clients, including late joiners.
local roundInfo = Instance.new("Folder")
roundInfo.Name = "RoundInfo"
roundInfo.Parent = ReplicatedStorage

local function setState(state: string, status: string)
	roundInfo:SetAttribute("State", state)
	roundInfo:SetAttribute("Status", status)
	roundInfo:SetAttribute("TimeLeft", 0)
end

local function setTimeLeft(seconds: number)
	roundInfo:SetAttribute("TimeLeft", seconds)
end

-- Who is still in the current round, and the connections watching each of them
local alive: { [Player]: boolean } = {}
local watchers: { [Player]: { RBXScriptConnection } } = {}

local function eliminate(player: Player)
	if not alive[player] then
		return
	end
	alive[player] = nil
	player:SetAttribute("InRound", false)
	local connections = watchers[player]
	if connections then
		for _, connection in connections do
			connection:Disconnect()
		end
		watchers[player] = nil
	end
end

Players.PlayerRemoving:Connect(eliminate)

-- Returns the character and humanoid only if the player is alive right now
local function getLivingCharacter(player: Player): (Model?, Humanoid?)
	local character = player.Character
	if not character or not character.Parent then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or not humanoid.RootPart then
		return nil, nil
	end
	return character, humanoid
end

-- Counts the sides still in the round (players, or teams when USE_TEAMS is on)
local function countSides(): (number, number)
	local sides: { [Instance]: boolean } = {}
	local sideCount = 0
	local playerCount = 0
	for player in alive do
		playerCount += 1
		local team = player.Team
		local side: Instance = if USE_TEAMS and team then team else player
		if not sides[side] then
			sides[side] = true
			sideCount += 1
		end
	end
	return sideCount, playerCount
end

-- STATE: Waiting and Intermission. Returns false if players left during the countdown.
local function runIntermission(): boolean
	while #Players:GetPlayers() < MIN_PLAYERS do
		setState("Waiting", `Waiting for players ({#Players:GetPlayers()}/{MIN_PLAYERS})`)
		task.wait(1)
	end
	setState("Intermission", "Intermission")
	for secondsLeft = INTERMISSION_SECONDS, 1, -1 do
		if #Players:GetPlayers() < MIN_PLAYERS then
			return false
		end
		setTimeLeft(secondsLeft)
		task.wait(1)
	end
	return true
end

-- STATE: Starting, part 1. Copy a random map (not the last one, if there is a choice).
local lastMapName = ""

local function loadMap(): Model?
	local allMaps: { Model } = {}
	local freshMaps: { Model } = {}
	for _, child in mapsFolder:GetChildren() do
		if child:IsA("Model") then
			table.insert(allMaps, child)
			if child.Name ~= lastMapName then
				table.insert(freshMaps, child)
			end
		end
	end
	local choices = if #freshMaps > 0 then freshMaps else allMaps
	if #choices == 0 then
		warn("RoundSystem: add at least one map Model to ServerStorage > Maps")
		return nil
	end
	local chosen = choices[random:NextInteger(1, #choices)]
	lastMapName = chosen.Name
	local map = chosen:Clone()
	map.Parent = workspace
	return map
end

local function getSpawnPoints(map: Model): { BasePart }
	local points: { BasePart } = {}
	local folder = map:FindFirstChild("Spawns")
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child)
			end
		end
	end
	-- Shuffle, so players do not land on the same spawn every round
	for i = #points, 2, -1 do
		local j = random:NextInteger(1, i)
		points[i], points[j] = points[j], points[i]
	end
	return points
end

-- How high a standing character's root part sits above the floor.
-- The formula is from Roblox's Humanoid.HipHeight reference (R6 rigs add the leg height).
local function rootHeight(character: Model, humanoid: Humanoid, rootPart: BasePart): number
	local height = rootPart.Size.Y / 2 + humanoid.HipHeight
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		if leg and leg:IsA("BasePart") then
			height += leg.Size.Y
		end
	end
	return height
end

-- STATE: Starting, part 2. Get ready, then teleport everyone who is alive.
local function startRound(map: Model): boolean
	local spawnPoints = getSpawnPoints(map)
	if #spawnPoints == 0 then
		warn(`RoundSystem: {map.Name} needs a Spawns folder with at least one part in it`)
		return false
	end

	-- With streaming on, ask each client to load the map before its character arrives
	if workspace.StreamingEnabled then
		local mapPosition = map:GetPivot().Position
		for _, player in Players:GetPlayers() do
			task.spawn(function()
				pcall(function()
					player:RequestStreamAroundAsync(mapPosition, GET_READY_SECONDS)
				end)
			end)
		end
	end

	setState("Starting", `Map: {map.Name}`)
	for secondsLeft = GET_READY_SECONDS, 1, -1 do
		setTimeLeft(secondsLeft)
		task.wait(1)
	end

	-- Only players who are alive right now take part. Everyone else waits for the next round.
	local participants: { Player } = {}
	for _, player in Players:GetPlayers() do
		if getLivingCharacter(player) then
			table.insert(participants, player)
		end
	end
	if #participants < MIN_PLAYERS then
		setState("Waiting", "Not enough players, starting over")
		task.wait(2)
		return false
	end

	for index, player in participants do
		local character, humanoid = getLivingCharacter(player)
		local rootPart = if humanoid then humanoid.RootPart else nil
		if character and humanoid and rootPart then
			local spawnPart = spawnPoints[(index - 1) % #spawnPoints + 1]
			-- A character's pivot is its root part, so lift it to standing height above the part
			local height = spawnPart.Size.Y / 2 + rootHeight(character, humanoid, rootPart)
			character:PivotTo(spawnPart.CFrame + Vector3.new(0, height, 0))
			alive[player] = true
			player:SetAttribute("InRound", true)
			watchers[player] = {
				humanoid.Died:Connect(function()
					eliminate(player)
				end),
				player.CharacterRemoving:Connect(function()
					eliminate(player)
				end),
			}
		end
	end
	return true
end

-- STATE: InRound. Ends when time runs out or only one side is left.
local function runRound()
	setState("InRound", "Round in progress")
	local startingSides = countSides()
	for secondsLeft = ROUND_SECONDS, 1, -1 do
		local _, playersLeft = countSides()
		roundInfo:SetAttribute("Status", `{playersLeft} left`)
		setTimeLeft(secondsLeft)
		task.wait(1)
		local sidesLeft = countSides()
		-- A round that started with one side (a solo test) only ends on time or death
		if sidesLeft == 0 or (startingSides > 1 and sidesLeft == 1) then
			break
		end
	end
end

-- STATE: Results. Everyone still alive wins.
local function awardWin(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins and wins:IsA("IntValue") then
		wins.Value += 1
	end
end

local function finishRound(): { Player }
	local sidesLeft = countSides()
	local winners: { Player } = {}
	for player in alive do
		table.insert(winners, player)
	end

	local message = `{#winners} players survived!`
	local firstTeam = if #winners > 0 then winners[1].Team else nil
	if #winners == 0 then
		message = "Nobody survived"
	elseif USE_TEAMS and sidesLeft == 1 and firstTeam then
		message = `{firstTeam.Name} wins!`
	elseif #winners == 1 then
		message = `{winners[1].DisplayName} wins!`
	end

	for _, player in winners do
		awardWin(player)
		eliminate(player) -- stop watching them; they stay on the map until cleanup
	end
	setState("Results", message)
	task.wait(RESULTS_SECONDS)
	return winners
end

-- STATE: Cleanup. Send survivors back to the lobby, then remove the map.
local function cleanup(map: Model, survivors: { Player })
	for _, player in survivors do
		if player.Parent then -- still in the server
			task.spawn(function()
				local ok, err = pcall(function()
					player:LoadCharacterAsync()
				end)
				if not ok then
					warn(`RoundSystem: could not respawn {player.Name}: {err}`)
				end
			end)
		end
	end
	map:Destroy()
end

-- The loop: one pass is one round
while true do
	if runIntermission() then
		local map = loadMap()
		if map then
			local survivors: { Player } = {}
			if startRound(map) then
				runRound()
				survivors = finishRound()
			end
			cleanup(map, survivors)
		else
			task.wait(5) -- no maps yet: try again shortly
		end
	end
end
