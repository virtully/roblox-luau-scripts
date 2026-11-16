--!strict
-- How to make a zombie survival game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-zombie-survival-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ZombieWaves
-- Script in ServerScriptService named ZombieWaves.
-- Spawns bigger, tougher waves of ServerStorage.Zombie at the parts in
-- Workspace.ZombieSpawns. Each zombie walks at the nearest living player.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local template = ServerStorage:WaitForChild("Zombie") :: Model -- a rig with a Humanoid
local spawns = workspace:WaitForChild("ZombieSpawns") :: Folder
local MAX_ALIVE = 25 -- zombies on the map at once; the rest wait their turn
local HIT_DAMAGE, HIT_RANGE, HIT_COOLDOWN = 10, 4, 1
local alive = 0

local function nearestPlayer(from: Vector3): (BasePart?, Humanoid?)
	local best, bestHumanoid, bestDistance = nil, nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and (root.Position - from).Magnitude < bestDistance then
			best, bestHumanoid, bestDistance = root, humanoid, (root.Position - from).Magnitude
		end
	end
	return best, bestHumanoid
end

local function spawnZombie(health: number, speed: number)
	local points = spawns:GetChildren()
	local zombie = template:Clone()
	local humanoid = zombie:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = zombie:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoid.MaxHealth, humanoid.Health, humanoid.WalkSpeed = health, health, speed
	zombie:PivotTo((points[math.random(#points)] :: BasePart).CFrame + Vector3.new(0, 3, 0))
	zombie.Parent = workspace
	root:SetNetworkOwner(nil) -- the server moves zombies, so no player can drag them
	alive += 1
	humanoid.Died:Once(function()
		alive -= 1
		task.delay(3, zombie.Destroy, zombie)
	end)
	local nextHit = 0
	while humanoid.Health > 0 and zombie.Parent do
		local target, victim = nearestPlayer(root.Position)
		if target and victim then
			humanoid:MoveTo(target.Position) -- straight line: walls and barricades stop it
			if (target.Position - root.Position).Magnitude < HIT_RANGE and os.clock() > nextHit then
				victim:TakeDamage(HIT_DAMAGE)
				nextHit = os.clock() + HIT_COOLDOWN
			end
		end
		task.wait(0.25)
	end
end

local wave = 0
while true do
	task.wait(15) -- break between waves: repair, buy, regroup
	wave += 1
	workspace:SetAttribute("Wave", wave)
	for _ = 1, 6 + wave * 4 do -- more zombies each wave, each a little tougher and faster
		while alive >= MAX_ALIVE do
			task.wait(1)
		end
		task.spawn(spawnZombie, 60 + wave * 15, math.min(10 + wave * 0.5, 16))
		task.wait(0.5)
	end
	repeat
		task.wait(1)
	until alive == 0
end
