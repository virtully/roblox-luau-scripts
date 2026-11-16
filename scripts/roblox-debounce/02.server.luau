--!strict
-- How to use a debounce in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-debounce
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named Trap
-- Script inside a Part named Trap.
-- Drops a ball when anyone steps on it, then waits 3 seconds before it can fire again.
local trap = script.Parent :: BasePart

local RESET_SECONDS = 3

local busy = false

trap.Touched:Connect(function(hit: BasePart)
	if busy then
		return
	end
	local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return -- not a character: do not start the cooldown for a loose part
	end
	busy = true

	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(4, 4, 4)
	ball.Position = trap.Position + Vector3.new(0, 30, 0)
	ball.Parent = workspace
	game:GetService("Debris"):AddItem(ball, 5)

	task.wait(RESET_SECONDS)
	busy = false
end)
