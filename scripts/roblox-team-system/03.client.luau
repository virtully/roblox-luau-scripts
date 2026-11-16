--!strict
-- How to make teams in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-team-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named TeamDoors
-- LocalScript in StarterPlayerScripts named TeamDoors.
-- Parts tagged "TeamDoor" with a "Team" attribute let only that team walk through.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function update(door: Instance)
	if not door:IsA("BasePart") then
		return
	end
	local allowed = door:GetAttribute("Team")
	local mine = player.Team and player.Team.Name
	-- Each device simulates its own character, so turning collision off here
	-- lets this player through while the door stays solid for everyone else
	door.CanCollide = not (mine ~= nil and allowed == mine)
end

local function updateAll()
	for _, door in CollectionService:GetTagged("TeamDoor") do
		update(door)
	end
end

CollectionService:GetInstanceAddedSignal("TeamDoor"):Connect(update)
player:GetPropertyChangedSignal("Team"):Connect(updateAll)
updateAll()
