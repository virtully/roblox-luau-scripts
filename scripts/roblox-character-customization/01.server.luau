--!strict
-- How to make character customization in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-character-customization
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Customization
-- Script in ServerScriptService named Customization.
-- The client asks for a change; the server only accepts colours, sizes and clothing
-- from the lists below, then applies them with a HumanoidDescription.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- What players may choose. Add clothing asset IDs from the Creator Store or Marketplace.
local SKIN_COLORS: { Color3 } = {
	Color3.fromRGB(255, 220, 177),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(90, 56, 37),
	Color3.fromRGB(110, 170, 255),
}
local SHIRTS: { number } = { 0 } -- 0 means no shirt; add shirt asset IDs here
local PANTS: { number } = { 0 }
local MIN_HEIGHT, MAX_HEIGHT = 0.9, 1.1 -- R15 height scale range
local COOLDOWN = 1 -- seconds between changes

local changeEvent = Instance.new("RemoteEvent")
changeEvent.Name = "ChangeLook"
changeEvent.Parent = ReplicatedStorage

local lastChange: { [Player]: number } = {}

local function setAllBodyColors(description: HumanoidDescription, color: Color3)
	description.HeadColor = color
	description.TorsoColor = color
	description.LeftArmColor = color
	description.RightArmColor = color
	description.LeftLegColor = color
	description.RightLegColor = color
end

changeEvent.OnServerEvent:Connect(function(player: Player, kind: unknown, value: unknown)
	if typeof(kind) ~= "string" or typeof(value) ~= "number" or value ~= value then
		return
	end
	local now = os.clock()
	if now - (lastChange[player] or -math.huge) < COOLDOWN then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	lastChange[player] = now

	-- Start from what the character wears now, and change one thing
	local description = humanoid:GetAppliedDescription()
	local index = math.floor(value)
	if kind == "skin" and SKIN_COLORS[index] then
		setAllBodyColors(description, SKIN_COLORS[index])
	elseif kind == "shirt" and SHIRTS[index] then
		description.Shirt = SHIRTS[index]
	elseif kind == "pants" and PANTS[index] then
		description.Pants = PANTS[index]
	elseif kind == "height" then
		description.HeightScale = math.clamp(value, MIN_HEIGHT, MAX_HEIGHT)
	else
		return
	end
	local ok, err = pcall(function()
		humanoid:ApplyDescriptionAsync(description)
	end)
	if not ok then
		warn("Customization: could not apply look for", player.Name, err)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastChange[player] = nil
end)
