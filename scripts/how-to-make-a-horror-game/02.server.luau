--!strict
-- How to make a horror game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-horror-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FlashlightServer
-- Script in ServerScriptService named FlashlightServer.
-- Every player has a flashlight with a battery the server drains and refills.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DRAIN_PER_SECOND = 2 -- a full battery lasts 50 seconds of light
local BATTERY_PICKUP = 40 -- charge a Battery part gives back

local toggle = Instance.new("RemoteEvent")
toggle.Name = "ToggleFlashlight"
toggle.Parent = ReplicatedStorage

local function getLight(player: Player): SpotLight?
	local head = player.Character and player.Character:FindFirstChild("Head")
	local light = head and head:FindFirstChild("Flashlight")
	return if light and light:IsA("SpotLight") then light else nil
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Battery", 100)
	player.CharacterAdded:Connect(function(character)
		local head = character:WaitForChild("Head")
		local light = Instance.new("SpotLight")
		light.Name = "Flashlight"
		light.Range, light.Angle, light.Brightness = 40, 45, 3
		light.Enabled = false
		light.Parent = head
	end)
end)

-- The client only asks; the server decides if there is charge left
toggle.OnServerEvent:Connect(function(player)
	local light = getLight(player)
	local battery = player:GetAttribute("Battery")
	if light and typeof(battery) == "number" then
		light.Enabled = not light.Enabled and battery > 0
	end
end)

for _, part in CollectionService:GetTagged("Battery") do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent :: Model)
			local battery = player and player:GetAttribute("Battery")
			if player and typeof(battery) == "number" and part.Parent then
				player:SetAttribute("Battery", math.min(100, battery + BATTERY_PICKUP))
				part:Destroy() -- one use; respawn them per round if you like
			end
		end)
	end
end

while true do
	task.wait(1)
	for _, player in Players:GetPlayers() do
		local light = getLight(player)
		local battery = player:GetAttribute("Battery")
		if light and light.Enabled and typeof(battery) == "number" then
			local left = math.max(0, battery - DRAIN_PER_SECOND)
			player:SetAttribute("Battery", left)
			light.Enabled = left > 0
		end
	end
end
