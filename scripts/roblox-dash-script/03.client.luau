--!strict
-- How to make a dash in Roblox Studio (Q to dash)
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-dash-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ImpulseDash
-- LocalScript in StarterPlayerScripts named ImpulseDash (an alternative to DashClient).
-- Press E for an instant shove instead of a held speed.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local DASH_SPEED = 60 -- speed added by the shove, in studs per second
local DASH_COOLDOWN = 1.5

local player = Players.LocalPlayer
local lastDash = -math.huge

local function onDash(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	local now = os.clock()
	if not (humanoid and root) or humanoid.Health <= 0 or now - lastDash < DASH_COOLDOWN then
		return Enum.ContextActionResult.Pass
	end
	lastDash = now
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	-- Impulse = mass times the change in speed, so every avatar gets the same speed
	root:ApplyImpulse(direction * DASH_SPEED * root.AssemblyMass)
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("ImpulseDash", onDash, true, Enum.KeyCode.E)
ContextActionService:SetTitle("ImpulseDash", "Shove")
