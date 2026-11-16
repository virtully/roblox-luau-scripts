--!strict
-- How to make a pet game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-pet-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PetCare
-- Script in ServerScriptService named PetCare.
-- Every so often a player's pet wants something. Doing it at the right station
-- pays Bucks and adds growth points; enough points and the pet ages up.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local NEEDS = { "Hungry", "Thirsty", "Sleepy", "Dirty", "Bored" }
local NEED_EVERY = 45 -- seconds between needs
local NEED_REWARD = 20 -- Bucks for each need the player completes
local STAGES = {
	{ name = "Baby", points = 0 },
	{ name = "Young", points = 6 },
	{ name = "Grown", points = 15 },
	{ name = "Elder", points = 30 },
}

local function stageFor(points: number): string
	local name = STAGES[1].name
	for _, stage in STAGES do
		if points >= stage.points then
			name = stage.name
		end
	end
	return name
end

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local bucks = Instance.new("IntValue")
	bucks.Name = "Bucks"
	bucks.Parent = stats
	stats.Parent = player
	-- Attributes on the player replicate, so a LocalScript can draw the need bubble
	player:SetAttribute("PetPoints", 0)
	player:SetAttribute("PetStage", stageFor(0))
end

-- A station is any part tagged "PetStation" with a "Fixes" attribute, such as "Hungry"
local function setUpStation(station: Instance)
	if not station:IsA("BasePart") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Care for pet"
	prompt.HoldDuration = 2
	prompt.Parent = station
	prompt.Triggered:Connect(function(player: Player)
		local need = player:GetAttribute("PetNeed")
		if need == nil or need ~= station:GetAttribute("Fixes") then
			return -- the pet does not want this right now
		end
		local stats = player:FindFirstChild("leaderstats")
		local bucks = stats and stats:FindFirstChild("Bucks")
		if bucks and bucks:IsA("IntValue") then
			bucks.Value += NEED_REWARD
		end
		local points = (tonumber(player:GetAttribute("PetPoints")) or 0) + 1
		player:SetAttribute("PetPoints", points)
		player:SetAttribute("PetStage", stageFor(points))
		player:SetAttribute("PetNeed", nil)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, station in CollectionService:GetTagged("PetStation") do
	setUpStation(station)
end
CollectionService:GetInstanceAddedSignal("PetStation"):Connect(setUpStation)

-- Hand out a new need to every pet that is not already waiting for one
while true do
	task.wait(NEED_EVERY)
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("PetNeed") == nil then
			player:SetAttribute("PetNeed", NEEDS[math.random(#NEEDS)])
		end
	end
end
