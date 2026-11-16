--!strict
-- How to generate terrain in Roblox Studio with a script
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-terrain-generator
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TerrainGenerator
-- Script in ServerScriptService named TerrainGenerator (or paste it into the Command Bar,
-- View > Command Bar, to build the terrain once in edit mode and save it with the place).
-- Islands with hills, beaches, a lake and the sea around them, made of real Terrain.
local SEED = 42 -- change it for a different coastline and hills
local CELL = 4 -- studs per column; Terrain voxels are 4 studs
local SEA_LEVEL = 0
local SEA_FLOOR = -24
local HILL_HEIGHT = 70 -- the tallest hills reach about this high
local ISLANDS = {
	{ center = Vector2.new(0, 0), radius = 260 },
	{ center = Vector2.new(330, 190), radius = 90 },
}
local LAKE = { center = Vector2.new(-60, 40), radius = 50, level = 14 }
local CLEAR_FIRST = false -- true wipes ALL existing terrain first

local RunService = game:GetService("RunService")
local terrain = workspace.Terrain

-- 0 at the coast, 1 in the middle of the nearest island, with a soft edge
local function islandMask(x: number, z: number): number
	local best = 0
	for _, island in ISLANDS do
		local d = (Vector2.new(x, z) - island.center).Magnitude / island.radius
		best = math.max(best, 1 - d * d)
	end
	return best
end

-- Height of the ground at (x, z): island shape + two layers of noise for hills
local function heightAt(x: number, z: number): number
	local mask = islandMask(x, z)
	if mask <= 0 then
		return SEA_FLOOR
	end
	local broad = math.noise(x / 180, z / 180, SEED) * 0.5 + 0.5
	local detail = math.noise(x / 45, z / 45, SEED + 10) * 0.25
	local h = SEA_LEVEL - 6 + mask * (12 + (broad + detail) * HILL_HEIGHT * mask)
	-- the lake: a bowl up to 8 studs deep, with a bank around it so the water stays in
	local lakeDist = (Vector2.new(x, z) - LAKE.center).Magnitude / LAKE.radius
	if lakeDist < 1 then
		h = LAKE.level - 8 * (1 - lakeDist * lakeDist)
	elseif lakeDist < 1.4 then
		h = math.max(h, LAKE.level + 2)
	end
	return h
end

local function surfaceMaterial(h: number): Enum.Material
	if h < SEA_LEVEL + 3 then
		return Enum.Material.Sand
	elseif h < SEA_LEVEL + 45 then
		return Enum.Material.Grass
	elseif h < SEA_LEVEL + 60 then
		return Enum.Material.Rock
	end
	return Enum.Material.Snow
end

if CLEAR_FIRST then
	terrain:Clear()
end

-- The extent to cover: every island plus a margin of sea
local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
for _, island in ISLANDS do
	minX = math.min(minX, island.center.X - island.radius - 60)
	maxX = math.max(maxX, island.center.X + island.radius + 60)
	minZ = math.min(minZ, island.center.Y - island.radius - 60)
	maxZ = math.max(maxZ, island.center.Y + island.radius + 60)
end

-- The sea first: one slab of water, then the land replaces it where it rises
local seaSize = Vector3.new(maxX - minX, SEA_LEVEL - SEA_FLOOR, maxZ - minZ)
terrain:FillBlock(CFrame.new((minX + maxX) / 2, (SEA_LEVEL + SEA_FLOOR) / 2, (minZ + maxZ) / 2), seaSize, Enum.Material.Water)
terrain:FillBlock(CFrame.new((minX + maxX) / 2, SEA_FLOOR - 4, (minZ + maxZ) / 2), Vector3.new(seaSize.X, 8, seaSize.Z), Enum.Material.Sand)

for x = minX, maxX, CELL do
	for z = minZ, maxZ, CELL do
		local h = heightAt(x, z)
		if h > SEA_FLOOR then
			local bottom = SEA_FLOOR - 8
			local top = math.max(h - 4, bottom + 1)
			-- the body of the column, then 4 studs of surface on top
			terrain:FillBlock(CFrame.new(x, (bottom + top) / 2, z), Vector3.new(CELL, top - bottom, CELL), Enum.Material.Rock)
			terrain:FillBlock(CFrame.new(x, top + 2, z), Vector3.new(CELL, 4, CELL), surfaceMaterial(h))
			-- land below sea level stays under water; inside the lake, water up to its level
			local waterTop = if (Vector2.new(x, z) - LAKE.center).Magnitude < LAKE.radius then LAKE.level else SEA_LEVEL
			if h < waterTop then
				terrain:FillBlock(CFrame.new(x, (h + waterTop) / 2, z), Vector3.new(CELL, waterTop - h, CELL), Enum.Material.Water)
			end
		end
	end
	if RunService:IsRunning() then
		task.wait() -- in a running game, one row per frame so the server does not stall
	end
end
print("TerrainGenerator: done")
