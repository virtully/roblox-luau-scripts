--!strict
-- How to raycast in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-raycast
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named Laser
-- Script inside a Part named Laser.
-- Casts a ray forward every second, prints the hit and draws the ray.
local laser = script.Parent :: BasePart

local RANGE = 50 -- studs

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { laser } -- do not hit the laser itself

local beam = Instance.new("Part")
beam.Anchored = true
beam.CanCollide = false
beam.CanQuery = false -- so later rays pass through the beam
beam.Material = Enum.Material.Neon
beam.Color = Color3.fromRGB(255, 60, 60)
beam.Parent = workspace

while true do
	local origin = laser.Position
	local direction = laser.CFrame.LookVector * RANGE
	local result = workspace:Raycast(origin, direction, params)

	local hitPoint = if result then result.Position else origin + direction
	local length = (hitPoint - origin).Magnitude
	beam.Size = Vector3.new(0.2, 0.2, length)
	beam.CFrame = CFrame.lookAt(origin, hitPoint) * CFrame.new(0, 0, -length / 2)

	if result then
		print("Hit", result.Instance.Name, "at", math.floor(result.Distance), "studs")
	end
	task.wait(1)
end
