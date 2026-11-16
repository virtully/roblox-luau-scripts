--!strict
-- How to make a natural disaster game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-natural-disaster-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Disasters
-- Script in ServerScriptService named Disasters.
-- Round loop: fresh map, random disaster, survivors win, reset.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local INTERMISSION = 15
local ROUND_TIME = 60
local maps = ServerStorage:WaitForChild("Maps")

local function setStatus(text: string, timeLeft: number)
	ReplicatedStorage:SetAttribute("Status", text)
	ReplicatedStorage:SetAttribute("TimeLeft", timeLeft)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

type Disaster = { name: string, run: (map: Model) -> () -> () }

local DISASTERS: { Disaster } = {
	{
		name = "Flood",
		run = function(map)
			local pivot = map:GetPivot()
			local water = Instance.new("Part")
			water.Name = "Flood"
			water.Anchored = true
			water.CanCollide = false
			water.Transparency = 0.4
			water.Color = Color3.fromRGB(40, 110, 200)
			water.Size = Vector3.new(400, 2, 400)
			water.CFrame = pivot * CFrame.new(0, -1, 0)
			water.Parent = map
			-- the top rises from the ground to 60 studs over the round
			local goal = { Size = Vector3.new(400, 62, 400), CFrame = pivot * CFrame.new(0, 30, 0) }
			TweenService:Create(water, TweenInfo.new(ROUND_TIME, Enum.EasingStyle.Linear), goal):Play()
			local running = true
			task.spawn(function()
				while running do
					local surface = water.Position.Y + water.Size.Y / 2
					for _, player in Players:GetPlayers() do
						local root = rootOf(player)
						local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
						if root and humanoid and root.Position.Y < surface - 2 then
							humanoid:TakeDamage(10) -- under water: 10 damage a second
						end
					end
					task.wait(1)
				end
			end)
			return function()
				running = false
			end
		end,
	},
	{
		name = "Meteor shower",
		run = function(map)
			local pivot = map:GetPivot()
			local running = true
			task.spawn(function()
				while running do
					local meteor = Instance.new("Part")
					meteor.Shape = Enum.PartType.Ball
					meteor.Size = Vector3.new(6, 6, 6)
					meteor.Material = Enum.Material.Basalt
					meteor.Position = (pivot * CFrame.new(math.random(-80, 80), 150, math.random(-80, 80))).Position
					local hitHumanoids: { [Humanoid]: boolean } = {}
					meteor.Touched:Connect(function(hit)
						local model = hit:FindFirstAncestorWhichIsA("Model")
						local humanoid = model and model:FindFirstChildOfClass("Humanoid")
						if humanoid and not hitHumanoids[humanoid] then
							hitHumanoids[humanoid] = true -- each meteor hurts a player once
							humanoid:TakeDamage(40)
						end
					end)
					meteor.Parent = map
					Debris:AddItem(meteor, 8) -- clean up so parts do not pile up
					task.wait(0.4)
				end
			end)
			return function()
				running = false
			end
		end,
	},
}

local function freshMap(): Model
	local templates = maps:GetChildren()
	local template = templates[math.random(1, #templates)] :: Model
	local map = template:Clone()
	map.Name = "CurrentMap"
	map.Parent = workspace
	return map
end

while true do
	for t = INTERMISSION, 1, -1 do
		setStatus("Intermission", t)
		task.wait(1)
	end

	local map = freshMap()
	local spawnPart = map:WaitForChild("MapSpawn") :: BasePart
	local alive: { [Player]: boolean } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health > 0 then
			character:PivotTo(spawnPart.CFrame + Vector3.new(math.random(-8, 8), 4, math.random(-8, 8)))
			alive[player] = true
			humanoid.Died:Once(function()
				alive[player] = nil
			end)
		end
	end

	local disaster = DISASTERS[math.random(1, #DISASTERS)]
	for t = 5, 1, -1 do
		setStatus(`{disaster.name} is coming!`, t)
		task.wait(1)
	end
	local stop = disaster.run(map)
	for t = ROUND_TIME, 1, -1 do
		setStatus(disaster.name, t)
		task.wait(1)
	end
	stop()

	for player in alive do
		if player.Parent then -- still in the server
			local wins = player:GetAttribute("Wins")
			player:SetAttribute("Wins", (if typeof(wins) == "number" then wins else 0) + 1)
		end
	end
	setStatus("Round over", 0)
	task.wait(3)
	map:Destroy()
	for _, player in Players:GetPlayers() do
		task.spawn(player.LoadCharacterAsync, player) -- everyone back to the lobby spawn
	end
end
