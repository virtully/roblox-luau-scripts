--!strict
-- How to make a horror game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-horror-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the monster model named MonsterAI
-- Script inside the monster model named MonsterAI.
-- Patrols numbered points, chases a player it sees or hears, gives up when it loses them.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local monster = script.Parent :: Model
local humanoid = monster:WaitForChild("Humanoid") :: Humanoid
local root = monster:WaitForChild("HumanoidRootPart") :: BasePart
local patrol = workspace:WaitForChild("PatrolPoints") :: Folder -- parts named 1, 2, 3...

local SIGHT_RANGE = 60 -- studs, needs a clear line
local HEAR_RANGE = 25 -- studs, through walls, only players with Sprinting = true
local PATROL_SPEED, CHASE_SPEED = 8, 17 -- walking is 16: running escapes it, but it hears running
local GIVE_UP_AFTER = 5 -- seconds without seeing or hearing anyone

root:SetNetworkOwner(nil) -- the server moves it, so it does not stutter
local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { monster }

-- Where the closest player it can see (or hear running) is, if any
local function findTarget(): Vector3?
	local best: Vector3?, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if character and hrp and hrp:IsA("BasePart") and hum and hum.Health > 0 then
			local offset = hrp.Position - root.Position
			local heard = offset.Magnitude < HEAR_RANGE and player:GetAttribute("Sprinting") == true
			local hit = if offset.Magnitude <= SIGHT_RANGE then workspace:Raycast(root.Position, offset, rayParams) else nil
			local seen = hit and hit.Instance:IsDescendantOf(character)
			if (heard or seen) and offset.Magnitude < bestDistance then
				best, bestDistance = hrp.Position, offset.Magnitude
			end
		end
	end
	return best
end

local function stepToward(goal: Vector3)
	local ok = pcall(function()
		path:ComputeAsync(root.Position, goal)
	end)
	local waypoints = if ok and path.Status == Enum.PathStatus.Success then path:GetWaypoints() else {}
	local nextPoint = waypoints[2] or waypoints[1]
	humanoid:MoveTo(if nextPoint then nextPoint.Position else goal) -- repathed 4 times a second
end

local lastKnown: Vector3?, lastSensed, patrolIndex = nil, 0, 1
while monster.Parent and humanoid.Health > 0 do
	local seen = findTarget()
	if seen then
		lastKnown, lastSensed = seen, os.clock()
	end
	if lastKnown and os.clock() - lastSensed < GIVE_UP_AFTER then
		humanoid.WalkSpeed = CHASE_SPEED
		stepToward(lastKnown) -- goes to where it last sensed you, not where you are now
	else
		lastKnown = nil
		humanoid.WalkSpeed = PATROL_SPEED
		local point = patrol:FindFirstChild(tostring(patrolIndex))
		if point and point:IsA("BasePart") then
			if (point.Position - root.Position).Magnitude < 4 then
				patrolIndex = patrolIndex % #patrol:GetChildren() + 1
			else
				stepToward(point.Position)
			end
		end
	end
	task.wait(0.25)
end
