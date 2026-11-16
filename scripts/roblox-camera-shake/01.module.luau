--!strict
-- How to make a camera shake in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-camera-shake
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named CameraShake
-- ModuleScript in ReplicatedStorage named CameraShake. Use it from LocalScripts only.
-- CameraShake.shake(amount) adds a shake (0 to 1); it fades out by itself.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_ANGLE = 6 -- degrees of tilt at full shake
local MAX_OFFSET = 0.4 -- studs of movement at full shake
local FREQUENCY = 18 -- how fast it wobbles
local DECAY_PER_SECOND = 1.2 -- how fast trauma falls

local CameraShake = {}
CameraShake.enabled = true

local trauma = 0
local seed = math.random() * 1000

local function noise(offset: number, t: number): number
	return math.noise(seed + offset, t * FREQUENCY) -- about -1 to 1
end

function CameraShake.shake(amount: number)
	trauma = math.clamp(trauma + amount, 0, 1)
end

local lastShake = CFrame.identity -- the offset added last frame

if RunService:IsClient() and Players.LocalPlayer then
	-- Before the camera script runs: take last frame's shake back out, because the
	-- camera script reads the camera's current direction and would keep it otherwise
	RunService:BindToRenderStep("CameraShakeUndo", Enum.RenderPriority.Camera.Value - 1, function()
		if lastShake ~= CFrame.identity then
			local camera = workspace.CurrentCamera
			camera.CFrame = camera.CFrame * lastShake:Inverse()
			lastShake = CFrame.identity
		end
	end)

	-- After the camera script runs: add this frame's shake on top
	RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, function(deltaTime: number)
		if trauma <= 0 then
			return
		end
		trauma = math.max(trauma - DECAY_PER_SECOND * deltaTime, 0)
		if not CameraShake.enabled then
			return
		end
		local strength = trauma * trauma
		local t = os.clock()
		local tilt = CFrame.Angles(
			math.rad(MAX_ANGLE * strength * noise(1, t)),
			math.rad(MAX_ANGLE * strength * noise(2, t)),
			math.rad(MAX_ANGLE * strength * noise(3, t))
		)
		local move = Vector3.new(noise(4, t), noise(5, t), 0) * MAX_OFFSET * strength
		lastShake = CFrame.new(move) * tilt
		local camera = workspace.CurrentCamera
		camera.CFrame = camera.CFrame * lastShake
	end)
end

return CameraShake
