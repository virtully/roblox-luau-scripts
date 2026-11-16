--!strict
-- How to make a roleplay game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-roleplay-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named HouseServer
-- Script in ServerScriptService named HouseServer.
-- One house per player: claim it at the door, lock or unlock it, and it frees up when they leave.
local Players = game:GetService("Players")

local houses = workspace:WaitForChild("Houses") :: Folder -- Models, each with a Part named Door
local owned: { [Player]: Model } = {}

local function setLocked(door: BasePart, locked: boolean)
	door.CanCollide = locked
	door.Transparency = if locked then 0 else 0.6
end

for _, house in houses:GetChildren() do
	local door = house:FindFirstChild("Door")
	if not house:IsA("Model") or not door or not door:IsA("BasePart") then
		continue
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Claim house"
	prompt.ObjectText = house.Name
	prompt.Parent = door
	setLocked(door, false)

	prompt.Triggered:Connect(function(player)
		local ownerId = house:GetAttribute("OwnerId")
		if ownerId == nil and not owned[player] then
			owned[player] = house
			house:SetAttribute("OwnerId", player.UserId)
			prompt.ObjectText = player.DisplayName .. "'s house"
			prompt.ActionText = "Lock"
		elseif ownerId == player.UserId then
			local locked = not door.CanCollide
			setLocked(door, locked)
			prompt.ActionText = if locked then "Unlock" else "Lock"
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	local house = owned[player]
	owned[player] = nil
	if not house then
		return
	end
	house:SetAttribute("OwnerId", nil)
	local door = house:FindFirstChild("Door")
	local prompt = door and door:FindFirstChildOfClass("ProximityPrompt")
	if door and door:IsA("BasePart") and prompt then
		setLocked(door, false)
		prompt.ActionText = "Claim house"
		prompt.ObjectText = house.Name
	end
end)
