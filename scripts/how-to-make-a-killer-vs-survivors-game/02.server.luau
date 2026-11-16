--!strict
-- How to make a killer vs survivors game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-killer-vs-survivors-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Generators
-- Script in ServerScriptService named Generators.
-- Survivors repair parts tagged "Generator" a step at a time. When every one is
-- done, the part named ExitGate opens and survivors who touch it escape.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local STEP = 10 -- progress per finished hold, out of 100
local survivorTeam = Teams:WaitForChild("Survivors") :: Team
local lobbyTeam = Teams:WaitForChild("Lobby") :: Team
local exitGate = workspace:WaitForChild("ExitGate") :: BasePart

local function allDone(): boolean
	for _, gen in CollectionService:GetTagged("Generator") do
		if (tonumber(gen:GetAttribute("Progress")) or 0) < 100 then
			return false
		end
	end
	return true
end

local function setUpGenerator(gen: Instance)
	if not gen:IsA("BasePart") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Repair"
	prompt.HoldDuration = 1.5 -- let go and you lose only the current step
	prompt.Parent = gen
	prompt.Triggered:Connect(function(player: Player)
		local progress = tonumber(gen:GetAttribute("Progress")) or 0
		if player.Team ~= survivorTeam or progress >= 100 then
			return -- only survivors repair, and only unfinished generators
		end
		gen:SetAttribute("Progress", math.min(progress + STEP, 100))
		if allDone() then
			workspace:SetAttribute("ExitOpen", true)
		end
	end)
end

for _, gen in CollectionService:GetTagged("Generator") do
	setUpGenerator(gen)
end
CollectionService:GetInstanceAddedSignal("Generator"):Connect(setUpGenerator)

exitGate.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	if player and player.Team == survivorTeam and workspace:GetAttribute("ExitOpen") == true then
		player.Team = lobbyTeam
		workspace:SetAttribute("Escaped", (tonumber(workspace:GetAttribute("Escaped")) or 0) + 1)
		player:LoadCharacterAsync() -- back to the lobby, safe from the killer
	end
end)
