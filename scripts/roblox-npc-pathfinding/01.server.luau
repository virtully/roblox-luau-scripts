--!strict
-- Roblox NPC pathfinding: make an NPC follow and chase players
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-pathfinding
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Chaser model named WalkToGoal
local PathfindingService = game:GetService("PathfindingService")

local npc = script.Parent :: Model
local humanoid = npc:WaitForChild("Humanoid") :: Humanoid
local rootPart = npc:WaitForChild("HumanoidRootPart") :: BasePart
local goalPart = workspace:WaitForChild("Goal") :: BasePart

-- The server has to own the NPC's physics for ChangeState (jumping) to work from a Script
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
})

-- ComputeAsync yields and can throw, so it goes inside pcall
local ok, err = pcall(function()
	path:ComputeAsync(rootPart.Position, goalPart.Position)
end)

if not ok then
	warn(`Path request failed: {err}`)
elseif path.Status ~= Enum.PathStatus.Success then
	warn(`No path to the goal: {path.Status.Name}`)
else
	for index, waypoint in path:GetWaypoints() do
		if index == 1 then
			continue -- the first waypoint is where the NPC is already standing
		end
		humanoid:MoveTo(waypoint.Position)
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		-- Wait until this waypoint is reached before moving to the next one
		local reached = humanoid.MoveToFinished:Wait()
		if not reached then
			warn(`{npc.Name} got stuck on the way to the goal`)
			break
		end
	end
end
