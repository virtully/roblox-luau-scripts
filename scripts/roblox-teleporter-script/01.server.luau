--!strict
-- How to make a teleporter in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-teleporter-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Teleporters
-- Script in ServerScriptService named Teleporters.
-- Every teleport is decided here, on the server:
--   1. Pads: touching a part in Workspace.TeleportPads takes you to the part named
--      in its Destination attribute.
--   2. A menu: the TeleportMenu LocalScript asks for a spot in Workspace.TeleportSpots
--      by name. The server checks the name, the cooldown and the Wins the spot needs.
--   3. Portals: touching a part in Workspace.PlacePortals sends you to the place
--      in its PlaceId attribute (another place in this game).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local PAD_COOLDOWN_SECONDS = 2 -- pads ignore a player this long after any teleport
local MENU_COOLDOWN_SECONDS = 3
local PAD_ARRIVAL_GAP = 3 -- studs in front of a destination pad, so players land beside it
local PLACE_ATTEMPTS = 3

local padFolder = workspace:FindFirstChild("TeleportPads")
local spotFolder = workspace:FindFirstChild("TeleportSpots")
local portalFolder = workspace:FindFirstChild("PlacePortals")

-- This script makes both remotes itself, so do not add them by hand
local getSpots = Instance.new("RemoteFunction")
getSpots.Name = "GetTeleportSpots"
getSpots.Parent = ReplicatedStorage
local teleportRequest = Instance.new("RemoteEvent")
teleportRequest.Name = "TeleportRequest"
teleportRequest.Parent = ReplicatedStorage

local lastTeleport: { [Player]: number } = {}
local warnedPads: { [Instance]: boolean } = {}
local leavingForPlace: { [Player]: boolean } = {}

local function playerFromHit(otherPart: BasePart): Player?
	local character = otherPart:FindFirstAncestorOfClass("Model")
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

local function onCooldown(player: Player, seconds: number): boolean
	return os.clock() - (lastTeleport[player] or -math.huge) < seconds
end

-- How high a standing character's root part sits above the floor.
-- The formula is from Roblox's Humanoid.HipHeight reference (R6 rigs add the leg height).
local function rootHeight(character: Model, humanoid: Humanoid, rootPart: BasePart): number
	local height = rootPart.Size.Y / 2 + humanoid.HipHeight
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		if leg and leg:IsA("BasePart") then
			height += leg.Size.Y
		end
	end
	return height
end

local function teleportTo(player: Player, destination: BasePart, besidePad: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not (character and humanoid and rootPart) or humanoid.Health <= 0 then
		return
	end
	lastTeleport[player] = os.clock() -- set before waiting, so a second touch cannot start a second teleport

	-- Face the way the destination's front face points (level, never tilted)
	local facing = destination.CFrame.LookVector * Vector3.new(1, 0, 1)
	if facing.Magnitude < 0.01 then
		facing = Vector3.new(0, 0, -1)
	end
	facing = facing.Unit
	-- Stand on its top face: a character's pivot is its root part, so lift it to standing height.
	-- A pad puts players a few studs in front of itself instead, because a player standing
	-- on a pad would set it off again with the next step.
	local lift = destination.Size.Y / 2 + rootHeight(character, humanoid, rootPart)
	local top = destination.Position + destination.CFrame.UpVector * lift
	if besidePad then
		top += facing * (destination.Size.Z / 2 + PAD_ARRIVAL_GAP)
	end
	local target = CFrame.lookAlong(top, facing)

	-- With instance streaming on, load the area around the destination first (up to 2 seconds)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 2)
	end)
	if player.Parent == nil or player.Character ~= character or humanoid.Health <= 0 then
		return -- left, respawned or died while the area loaded
	end
	-- A seated character is welded to its seat, and moving it would bring the seat along.
	-- Destroying the SeatWeld gets the character out of the seat first.
	local seat = humanoid.SeatPart
	if seat then
		local seatWeld = seat:FindFirstChild("SeatWeld")
		if seatWeld then
			seatWeld:Destroy()
		end
	end
	character:PivotTo(target)
	-- Start the cooldown again on arrival: the pre-fetch above can take up to 2 seconds,
	-- and the pad they land on must not send them straight back
	lastTeleport[player] = os.clock()
	player:SetAttribute("MovementCheckSkip", true) -- for a speed check script, if you have one
end

-- 1. Pads
if padFolder then
	for _, pad in padFolder:GetChildren() do
		if pad:IsA("BasePart") then
			pad.Touched:Connect(function(otherPart: BasePart)
				local player = playerFromHit(otherPart)
				local destinationName = pad:GetAttribute("Destination")
				if not player or typeof(destinationName) ~= "string" or onCooldown(player, PAD_COOLDOWN_SECONDS) then
					return
				end
				local destination = padFolder:FindFirstChild(destinationName)
				if destination and destination:IsA("BasePart") then
					teleportTo(player, destination, true)
				elseif not warnedPads[pad] then
					warnedPads[pad] = true -- warn once, not on every touch
					warn(`Teleporters: {pad.Name} points to {destinationName}, which is not a part in TeleportPads`)
				end
			end)
		end
	end
end

-- 2. The menu: the list of spots, then a request by name
local function winsOf(player: Player): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	return if wins and wins:IsA("IntValue") then wins.Value else 0
end

local function winsNeeded(spot: Instance): number
	local value = spot:GetAttribute("WinsNeeded")
	return if typeof(value) == "number" then value else 0
end

getSpots.OnServerInvoke = function(_player: Player)
	local list = {}
	if spotFolder then
		for _, spot in spotFolder:GetChildren() do
			if spot:IsA("BasePart") then
				table.insert(list, { name = spot.Name, winsNeeded = winsNeeded(spot) })
			end
		end
	end
	table.sort(list, function(a, b)
		if a.winsNeeded ~= b.winsNeeded then
			return a.winsNeeded < b.winsNeeded
		end
		return a.name < b.name -- same Wins: alphabetical, so the order never changes
	end)
	return list
end

teleportRequest.OnServerEvent:Connect(function(player: Player, spotName: unknown)
	-- The client sends only a name. Never accept a position or a CFrame from a client.
	if typeof(spotName) ~= "string" or #spotName > 50 or not spotFolder then
		return
	end
	if onCooldown(player, MENU_COOLDOWN_SECONDS) then
		return
	end
	local spot = spotFolder:FindFirstChild(spotName)
	if not (spot and spot:IsA("BasePart")) then
		return
	end
	if winsOf(player) < winsNeeded(spot) then
		return -- locked for this player
	end
	teleportTo(player, spot, false)
end)

-- 3. Portals to another place in this game
local function sendToPlace(player: Player, placeId: number)
	if leavingForPlace[player] or onCooldown(player, PAD_COOLDOWN_SECONDS) then
		return -- already on the way, or touched a teleporter a moment ago
	end
	lastTeleport[player] = os.clock()
	if RunService:IsStudio() then
		print(`Teleporters: would send {player.Name} to place {placeId}. Place teleports only work in the published game.`)
		return
	end
	leavingForPlace[player] = true
	for attempt = 1, PLACE_ATTEMPTS do
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(placeId, { player })
		end)
		if ok then
			return
		end
		warn(`Teleporters: teleport attempt {attempt} for {player.Name} failed: {err}`)
		task.wait(2)
	end
	leavingForPlace[player] = nil -- give up; touching the portal again tries again
end

-- A teleport can also fail after it starts. The player stays here and may try again.
TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
	warn(`Teleporters: {player.Name} could not leave ({result.Name}): {message}`)
	leavingForPlace[player] = nil
end)

if portalFolder then
	for _, portal in portalFolder:GetChildren() do
		if portal:IsA("BasePart") then
			portal.Touched:Connect(function(otherPart: BasePart)
				local player = playerFromHit(otherPart)
				local placeId = portal:GetAttribute("PlaceId")
				if player and typeof(placeId) == "number" and placeId > 0 then
					sendToPlace(player, placeId)
				end
			end)
		end
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastTeleport[player] = nil
	leavingForPlace[player] = nil
end)
