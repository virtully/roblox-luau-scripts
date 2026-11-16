--!strict
-- How to make a game like Steal a Brainrot in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-steal-a-brainrot-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named BuildStealMap
-- Script in ServerScriptService named BuildStealMap.
-- Makes a simple test map once: a conveyor down the middle and bases on both sides.
-- Delete this script when you build your own map with the same names.
local BASE_COUNT = 6 -- bases, half on each side of the conveyor
local SLOTS_PER_BASE = 8

if workspace:FindFirstChild("Bases") then
	return -- the map is already there
end

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The conveyor: units ride from Start to End
local conveyor = Instance.new("Folder")
conveyor.Name = "Conveyor"
conveyor.Parent = workspace
local length = 40 * (BASE_COUNT / 2) + 40
part("Belt", Vector3.new(10, 1, length), CFrame.new(0, 0.5, 0), Color3.fromRGB(45, 45, 55), conveyor)
local startPart = part("Start", Vector3.new(10, 1, 2), CFrame.new(0, 1.5, -length / 2), Color3.fromRGB(80, 200, 120), conveyor)
local endPart = part("End", Vector3.new(10, 1, 2), CFrame.new(0, 1.5, length / 2), Color3.fromRGB(220, 80, 80), conveyor)
startPart.CanCollide = false
endPart.CanCollide = false

local bases = Instance.new("Folder")
bases.Name = "Bases"
bases.Parent = workspace

for i = 1, BASE_COUNT do
	local side = if i % 2 == 1 then -1 else 1
	local row = math.ceil(i / 2) - 1
	local z = -length / 2 + 40 + row * 40
	local origin = CFrame.new(side * 40, 0, z)

	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base.Parent = bases
	local floor = part("Floor", Vector3.new(36, 1, 32), origin * CFrame.new(0, 0.5, 0), Color3.fromRGB(70, 90, 140), base)
	base.PrimaryPart = floor

	-- Home: where the owner spawns and where stolen units are delivered
	local home = part("Home", Vector3.new(8, 1, 8), origin * CFrame.new(side * 12, 1.1, 0), Color3.fromRGB(240, 200, 60), base)
	home.CanCollide = false

	-- Barrier: the entrance on the conveyor side, solid only while the base is locked
	local barrier = part("Barrier", Vector3.new(1, 10, 32), origin * CFrame.new(-side * 18, 5.5, 0), Color3.fromRGB(120, 180, 255), base)
	barrier.Transparency = 1
	barrier.CanCollide = false

	-- Walls on the other three sides, so the entrance is the only way in
	local wallColor = Color3.fromRGB(55, 70, 110)
	part("BackWall", Vector3.new(1, 10, 32), origin * CFrame.new(side * 18, 5.5, 0), wallColor, base)
	part("SideWallA", Vector3.new(36, 10, 1), origin * CFrame.new(0, 5.5, -16), wallColor, base)
	part("SideWallB", Vector3.new(36, 10, 1), origin * CFrame.new(0, 5.5, 16), wallColor, base)

	local lockButton = part("LockButton", Vector3.new(4, 1, 4), origin * CFrame.new(side * 12, 1.1, 10), Color3.fromRGB(255, 90, 90), base)
	lockButton.CanCollide = false

	local slots = Instance.new("Folder")
	slots.Name = "Slots"
	slots.Parent = base
	for s = 1, SLOTS_PER_BASE do
		local col = (s - 1) % 4
		local rowS = math.floor((s - 1) / 4)
		local slot = part("Slot" .. s, Vector3.new(5, 1, 5), origin * CFrame.new(-side * (2 + rowS * 7), 1.1, -12 + col * 8), Color3.fromRGB(200, 200, 210), slots)
		slot.CanCollide = false
	end
end
