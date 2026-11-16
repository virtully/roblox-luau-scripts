--!strict
-- How to make a parkour game in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-parkour-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named WallJump
-- LocalScript in StarterPlayer > StarterCharacterScripts named WallJump.
-- Press jump in the air while facing a wall to kick off it. It runs in a
-- LocalScript so the jump answers the key press with no round trip to the server.
local UserInputService = game:GetService("UserInputService")

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart

local REACH = 3 -- studs from the body to the wall
local PUSH = 35 -- speed away from the wall
local LIFT = 50 -- upward speed
local COOLDOWN = 0.35

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { character }
local lastJump = 0

UserInputService.JumpRequest:Connect(function()
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return -- on the ground, the normal jump happens
	end
	if os.clock() - lastJump < COOLDOWN then
		return
	end
	local result = workspace:Raycast(root.Position, root.CFrame.LookVector * REACH, params)
	if not result then
		return
	end
	lastJump = os.clock()
	local away = Vector3.new(result.Normal.X, 0, result.Normal.Z)
	if away.Magnitude > 0 then
		away = away.Unit
	end
	root.AssemblyLinearVelocity = away * PUSH + Vector3.new(0, LIFT, 0)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + away) -- turn to face away
end)
