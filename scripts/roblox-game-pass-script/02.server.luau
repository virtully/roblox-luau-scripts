--!strict
-- Roblox game pass script: sell perks the right way
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-game-pass-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GamePassHandler
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- What the PassConfig module returns, so strict type checking can check how it is used
type PassConfigModule = {
	ids: { [string]: number },
	attributeFor: (passName: string) -> string,
}

local PassConfig = require(ReplicatedStorage:WaitForChild("PassConfig")) :: PassConfigModule
local passItems = ServerStorage:WaitForChild("PassItems")

-- Roblox's docs say Studio does not mock pass purchasing. Set this to true to try every
-- perk while testing in Studio. RunService:IsStudio() is false on live servers, so this
-- never gives perks away in the published game.
local GRANT_ALL_IN_STUDIO = false

local SPEED_PASS_WALK_SPEED = 24 -- the default WalkSpeed is 16
local VIP_PLAYERS_GROUP = "VIPPlayers"
local VIP_DOOR_GROUP = "VIPDoor"
local CHECK_ATTEMPTS = 3

-- passesOwned[player] holds the passes that player owns, e.g. passesOwned[player].VIP == true
local passesOwned: { [Player]: { [string]: boolean } } = {}

-- VIP door: parts in the VIPDoor group block everyone except characters in VIPPlayers
for _, groupName in { VIP_PLAYERS_GROUP, VIP_DOOR_GROUP } do
	if not workspace:IsCollisionGroupRegistered(groupName) then
		workspace:RegisterCollisionGroup(groupName)
	end
end
workspace:CollisionGroupSetCollidable(VIP_PLAYERS_GROUP, VIP_DOOR_GROUP, false)

local vipDoor = workspace:FindFirstChild("VIPDoor")
if vipDoor and vipDoor:IsA("BasePart") then
	vipDoor.CollisionGroup = VIP_DOOR_GROUP
else
	warn("No Part named VIPDoor in Workspace, so the VIP pass opens no door")
end

local function giveTool(player: Player, toolName: string)
	local template = passItems:FindFirstChild(toolName)
	if not (template and template:IsA("Tool")) then
		warn(`ServerStorage.PassItems has no Tool named {toolName}`)
		return
	end
	-- StarterGear: Roblox copies it into the Backpack every time the character spawns.
	-- It can appear a moment after the player joins, so wait for it briefly.
	local starterGear = player:WaitForChild("StarterGear", 10)
	if starterGear and starterGear:IsA("StarterGear") then
		template:Clone().Parent = starterGear
	else
		warn(`No StarterGear for {player.Name}, so {toolName} will not come back after a respawn`)
	end
	-- Backpack: if the character is already in the world, hand over a copy now too
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and player.Character then
		template:Clone().Parent = backpack
	end
end

-- Perks that live on the character. A respawn creates a new character without them,
-- so this runs for the current character and again for every new one.
local function applyCharacterPerks(player: Player, character: Model)
	local owned = passesOwned[player]
	if not owned then
		return
	end

	if owned.VIP then
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = VIP_PLAYERS_GROUP
			end
		end
	end

	if owned.Speed then
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.WalkSpeed = SPEED_PASS_WALK_SPEED
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- Accessories and other parts can arrive after the character spawns
	character.DescendantAdded:Connect(function(descendant: Instance)
		local owned = passesOwned[player]
		if owned and owned.VIP and descendant:IsA("BasePart") then
			descendant.CollisionGroup = VIP_PLAYERS_GROUP
		end
	end)
	applyCharacterPerks(player, character)
end

-- Gives a player everything one pass includes. Safe to call more than once.
local function grantPass(player: Player, passName: string)
	local owned = passesOwned[player]
	if not owned or owned[passName] then
		return -- the player has left, or already has this pass
	end
	owned[passName] = true
	-- Attributes set by the server replicate, so the player's LocalScripts can show "Owned"
	player:SetAttribute(PassConfig.attributeFor(passName), true)

	if passName == "GravityCoil" then
		giveTool(player, "GravityCoil")
	end

	local character = player.Character
	if character then
		applyCharacterPerks(player, character)
	end
end

-- Asks Roblox whether the player owns one pass, retrying if the request fails
local function checkPass(player: Player, passName: string, passId: number)
	for attempt = 1, CHECK_ATTEMPTS do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok then
			if result == true then
				grantPass(player, passName)
			end
			return
		end
		warn(`Could not check the {passName} pass for {player.Name} (try {attempt}): {result}`)
		if attempt < CHECK_ATTEMPTS then
			task.wait(attempt * 2)
			if not passesOwned[player] then
				return -- the player left while we waited
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	passesOwned[player] = {}

	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
	local character = player.Character
	if character then
		onCharacterAdded(player, character)
	end

	for passName, passId in PassConfig.ids do
		if GRANT_ALL_IN_STUDIO and RunService:IsStudio() then
			task.spawn(grantPass, player, passName)
		elseif passId ~= 0 then
			-- One thread per pass: Roblox can batch checks started together into fewer requests
			task.spawn(checkPass, player, passName, passId)
		end
	end
end

-- A player bought a pass in this server. Listen on the server only: here
-- wasPurchased is the final result, and a LocalScript's copy is not to be relied on.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(
	function(player: Player, passId: number, wasPurchased: boolean)
		if not wasPurchased then
			return
		end
		for passName, id in PassConfig.ids do
			if id == passId then
				grantPass(player, passName)
			end
		end
	end
)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	passesOwned[player] = nil
end)
