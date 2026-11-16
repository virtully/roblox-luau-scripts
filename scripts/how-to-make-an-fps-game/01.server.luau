--!strict
-- How to make an FPS game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-fps-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SafeSpawns
-- Script in ServerScriptService named SafeSpawns.
-- Puts each player, every time they spawn, at the spawn point farthest from
-- their enemies, with a short ForceField so nobody is shot on arrival.
local Players = game:GetService("Players")

local spawnPoints = workspace:WaitForChild("SpawnPoints") :: Folder -- plain parts
local SPAWN_SHIELD = 2 -- seconds of ForceField after each spawn

local function isEnemy(a: Player, b: Player): boolean
	return a ~= b and (not a.Team or a.Team ~= b.Team)
end

local function safestSpawn(player: Player): BasePart?
	local best: BasePart?, bestScore = nil, -math.huge
	for _, point in spawnPoints:GetChildren() do
		if point:IsA("BasePart") then
			local nearestEnemy = 500 -- counts as "far" when nobody is around
			for _, other in Players:GetPlayers() do
				local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if isEnemy(player, other) and root and root:IsA("BasePart") then
					nearestEnemy = math.min(nearestEnemy, (root.Position - point.Position).Magnitude)
				end
			end
			local score = nearestEnemy + math.random() * 15 -- a little noise so spawns are not predictable
			if score > bestScore then
				best, bestScore = point, score
			end
		end
	end
	return best
end

local function onCharacter(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart")
	local point = safestSpawn(player)
	if point then
		character:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
	end
	local shield = Instance.new("ForceField") -- TakeDamage does nothing while it is there
	shield.Parent = character
	task.delay(SPAWN_SHIELD, shield.Destroy, shield)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
end)
