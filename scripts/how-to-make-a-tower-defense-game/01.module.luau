--!strict
-- How to make a tower defense game in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-tower-defense-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Enemies
-- ModuleScript in ServerScriptService named Enemies.
-- Moves every enemy along the numbered parts in Workspace.Waypoints and
-- keeps the list towers read from. Requiring it starts the movement.
local RunService = game:GetService("RunService")

export type Enemy = { part: BasePart, health: number, speed: number, distance: number, reward: number }

local Enemies = { alive = {} :: { Enemy }, baseHealth = 100 }

local folder = workspace:WaitForChild("Waypoints") :: Folder
local points: { Vector3 } = {}
for i = 1, #folder:GetChildren() do
	local p = folder:WaitForChild(tostring(i)) :: BasePart
	points[i] = p.Position
end

-- Where an enemy is after walking this many studs along the path (nil = at the end)
local function placeAt(distance: number): CFrame?
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = (b - a).Magnitude
		if distance < length then
			return CFrame.lookAt(a:Lerp(b, distance / length), b)
		end
		distance -= length
	end
	return nil
end

function Enemies.spawn(health: number, speed: number, reward: number)
	local part = Instance.new("Part")
	part.Size = Vector3.new(2, 2, 2)
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(points[1])
	part.Parent = workspace
	local enemy: Enemy = { part = part :: BasePart, health = health, speed = speed, distance = 0, reward = reward }
	table.insert(Enemies.alive, enemy)
end

RunService.Heartbeat:Connect(function(dt)
	for i = #Enemies.alive, 1, -1 do
		local enemy = Enemies.alive[i]
		enemy.distance += enemy.speed * dt
		local cframe = if enemy.health > 0 then placeAt(enemy.distance) else nil
		if cframe then
			enemy.part.CFrame = cframe
		else
			if enemy.health > 0 then -- reached the end: it hurts the base
				Enemies.baseHealth = math.max(0, Enemies.baseHealth - enemy.health)
				workspace:SetAttribute("BaseHealth", Enemies.baseHealth)
			end
			enemy.part:Destroy()
			table.remove(Enemies.alive, i)
		end
	end
end)

return Enemies
