--!strict
-- Roblox NPC pathfinding: make an NPC follow and chase players
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-pathfinding
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Chaser model named ChaseAI
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local npc = script.Parent :: Model
local humanoid = npc:WaitForChild("Humanoid") :: Humanoid
local rootPart = npc:WaitForChild("HumanoidRootPart") :: BasePart

-- Settings (distances in studs, times in seconds)
local DETECTION_RANGE = 80 -- players further away than this are ignored
local STOP_DISTANCE = 4 -- stop this close to the target (0 = walk into them, for touch damage)
local DIRECT_CHASE_RANGE = 30 -- inside this range, skip pathfinding when nothing is in the way
local REPATH_DISTANCE = 4 -- how far the target must move before the path is recomputed
local MIN_REPATH_INTERVAL = 0.5 -- never compute paths more often than this
local WAYPOINT_TIMEOUT = 2 -- give up on a path if one waypoint takes longer than this
local CHASE_SPEED = 14 -- a player walks at 16 by default, so they can outrun this NPC
local HOME_RADIUS = 4 -- this close to home counts as being home
local RAY_HEIGHTS = { 0, -2 } -- line-of-sight rays at waist height and near the knees

local HOME = rootPart.Position -- where the NPC goes back to when nobody is in range

humanoid.WalkSpeed = CHASE_SPEED

-- Let the server simulate the NPC. Otherwise Roblox can hand its physics to a
-- nearby player's device, and the NPC stutters as that changes.
local canSetOwner, ownerProblem = rootPart:CanSetNetworkOwnership()
if not canSetOwner then
	warn(`{npc.Name} cannot move: {ownerProblem}. Untick Anchored on every part of the rig.`)
	return
end
rootPart:SetNetworkOwner(nil)

local path = PathfindingService:CreatePath({
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	Costs = {
		Water = 20, -- wade through water only to avoid a long detour
		DangerZone = math.huge, -- never enter regions labelled DangerZone
	},
})

-- The path the NPC is following right now
local waypoints: { PathWaypoint } = {}
local nextIndex = 0
local pathGoal: Vector3? = nil
local pathBlocked = false
local lastComputeTime = -math.huge

-- Blocked can fire for a waypoint the NPC has already passed. Only a block ahead matters.
path.Blocked:Connect(function(blockedIndex: number)
	if blockedIndex >= nextIndex then
		pathBlocked = true
	end
end)

local rayParams = RaycastParams.new()
rayParams.RespectCanCollide = true -- parts nothing can collide with do not block the view

local function clearPath()
	waypoints = {}
	nextIndex = 0
	pathGoal = nil
end

local function stopMoving()
	clearPath()
	humanoid:MoveTo(rootPart.Position)
end

-- The HumanoidRootPart of the closest living player within DETECTION_RANGE, or nil
local function findNearestTarget(): BasePart?
	local nearestRoot: BasePart? = nil
	local nearestDistance = DETECTION_RANGE
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
			local distance = (targetRoot.Position - rootPart.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestRoot = targetRoot
			end
		end
	end
	return nearestRoot
end

-- True when the target is on roughly the same level and nothing solid is in between.
-- A clear ray does not prove the ground is walkable, so this is only used at short range.
local function canSeeDirectly(targetRoot: BasePart): boolean
	local offset = targetRoot.Position - rootPart.Position
	if math.abs(offset.Y) > 3 then
		return false
	end
	local character = targetRoot.Parent
	rayParams.ExcludeInstances = if character then { npc, character } else { npc }
	for _, height in RAY_HEIGHTS do
		local origin = rootPart.Position + Vector3.new(0, height, 0)
		if workspace:Raycast(origin, offset, rayParams) then
			return false
		end
	end
	return true
end

local function computePath(goal: Vector3)
	lastComputeTime = os.clock()
	local ok, err = pcall(function()
		path:ComputeAsync(rootPart.Position, goal)
	end)
	-- Reset after computing, so a Blocked event from the old route cannot mark the new one
	pathBlocked = false
	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
		nextIndex = 2 -- waypoint 1 is where the NPC is standing
		pathGoal = goal
	else
		if not ok then
			warn(`{npc.Name}: path request failed: {err}`)
		end
		clearPath() -- no route right now; the main loop tries again shortly
	end
end

local function needsNewPath(goal: Vector3): boolean
	if os.clock() - lastComputeTime < MIN_REPATH_INTERVAL then
		return false -- computed a moment ago: keep walking the current path
	end
	local currentGoal = pathGoal
	if currentGoal == nil or pathBlocked or nextIndex > #waypoints then
		return true
	end
	return (goal - currentGoal).Magnitude > REPATH_DISTANCE
end

-- Waits for MoveToFinished, but gives up after `timeout` seconds instead of the
-- built-in 8, so a stuck NPC gets a new path quickly
local function waitForMoveToFinished(timeout: number): boolean
	local finished = false
	local reachedGoal = false
	local connection = humanoid.MoveToFinished:Connect(function(reached: boolean)
		finished = true
		reachedGoal = reached
	end)
	local deadline = os.clock() + timeout
	while not finished and os.clock() < deadline do
		task.wait()
	end
	connection:Disconnect()
	return reachedGoal
end

local function walkToNextWaypoint()
	local waypoint = waypoints[nextIndex]
	humanoid:MoveTo(waypoint.Position)
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	if waitForMoveToFinished(WAYPOINT_TIMEOUT) then
		nextIndex += 1
	else
		clearPath() -- stuck or pushed off course: compute a fresh path
	end
end

while humanoid.Health > 0 do
	local targetRoot = findNearestTarget()
	local goal: Vector3

	if targetRoot then
		local distance = (targetRoot.Position - rootPart.Position).Magnitude
		if distance <= STOP_DISTANCE then
			stopMoving() -- close enough: stay next to the target
			task.wait(0.2)
			continue
		end
		if distance <= DIRECT_CHASE_RANGE and canSeeDirectly(targetRoot) then
			clearPath()
			-- Passing the part as well makes the NPC follow it as it moves
			humanoid:MoveTo(targetRoot.Position, targetRoot)
			task.wait(0.15)
			continue
		end
		goal = targetRoot.Position
	else
		if (HOME - rootPart.Position).Magnitude <= HOME_RADIUS then
			stopMoving() -- nobody around and already home
			task.wait(0.5)
			continue
		end
		goal = HOME
	end

	if needsNewPath(goal) then
		computePath(goal)
	end

	if nextIndex >= 2 and nextIndex <= #waypoints then
		walkToNextWaypoint()
	else
		task.wait(0.1) -- no usable path yet, for example the target is out of reach
	end
end
