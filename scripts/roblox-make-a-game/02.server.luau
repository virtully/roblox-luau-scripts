--!strict
-- How to make a game in Roblox Studio, step by step
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-make-a-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CourseService
-- Script in ServerScriptService named CourseService.
-- Runs the course on the server, so every player sees the same thing and nobody can
-- give themselves coins: lava parts reset players, coins pay 1 Coin and come back,
-- and the Finish pad gives a Win to players who collected enough coins on this run.

local Players = game:GetService("Players")

local COINS_TO_FINISH = 3 -- coins a player must collect on a run before Finish counts
local COIN_RESPAWN_SECONDS = 10

local course = workspace:WaitForChild("Course")
local lavaFolder = course:WaitForChild("Lava")
local coinFolder = course:WaitForChild("Coins")
local finish = course:WaitForChild("Finish") :: BasePart
local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawnLocation then
	warn("CourseService: no SpawnLocation directly in Workspace, so the Finish cannot send players back")
end

-- Coins collected on this run: since the player last spawned or reached the Finish
local runCoins: { [Player]: number } = {}

-- Finds the player whose character touched a part, or nil for anything else
local function playerFromHit(otherPart: BasePart): Player?
	local character = otherPart:FindFirstAncestorOfClass("Model")
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

local function addStat(player: Player, statName: string, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	if stat and stat:IsA("IntValue") then
		stat.Value += amount
	end
end

-- Lava: any part in the Lava folder resets the player who touches it
for _, lava in lavaFolder:GetChildren() do
	if lava:IsA("BasePart") then
		lava.Touched:Connect(function(otherPart: BasePart)
			local character = otherPart:FindFirstAncestorOfClass("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
end

-- Coins: the first player to touch a coin gets it, then it hides until it respawns
for _, coin in coinFolder:GetChildren() do
	if coin:IsA("BasePart") then
		local shownTransparency = coin.Transparency
		local taken = false
		coin.Touched:Connect(function(otherPart: BasePart)
			local player = playerFromHit(otherPart)
			if not player or taken then
				return -- not a player, or this coin was already taken
			end
			taken = true
			coin.Transparency = 1
			addStat(player, "Coins", 1)
			runCoins[player] = (runCoins[player] or 0) + 1
			task.delay(COIN_RESPAWN_SECONDS, function()
				coin.Transparency = shownTransparency
				taken = false
			end)
		end)
	end
end

-- Finish: a Win for players who did the course, then back to the start
finish.Touched:Connect(function(otherPart: BasePart)
	local player = playerFromHit(otherPart)
	if not player or (runCoins[player] or 0) < COINS_TO_FINISH then
		return
	end
	runCoins[player] = 0 -- set first, so touching the pad again does not count twice
	addStat(player, "Wins", 1)
	local character = player.Character
	if character and spawnLocation then
		character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 4, 0))
		player:SetAttribute("MovementCheckSkip", true) -- for a speed check script, if you add one
	end
end)

-- A new character (after a reset or a fall) starts a new run
local function onPlayerAdded(player: Player)
	runCoins[player] = 0
	player.CharacterAdded:Connect(function()
		runCoins[player] = 0
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- anyone who joined while this script waited for Course
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	runCoins[player] = nil
end)
