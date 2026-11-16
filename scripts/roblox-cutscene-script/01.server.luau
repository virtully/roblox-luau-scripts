--!strict
-- How to make a cutscene in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-cutscene-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CutsceneService
-- Script in ServerScriptService named CutsceneService.
-- Decides who sees which cutscene and when. It reads the camera shots from numbered
-- parts in Workspace.Cutscenes, holds the player still, and tells that player's
-- device to play the shots. The camera itself can only be moved on the device.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings
local INTRO_CUTSCENE = "Intro" -- plays once when a player first spawns; "" for none
local DEFAULT_MOVE_SECONDS = 3 -- time to glide to a shot when it has no MoveSeconds
local DEFAULT_HOLD_SECONDS = 1 -- time to stay on a shot when it has no HoldSeconds
local MAX_SHOTS = 30

local cutscenes = workspace:WaitForChild("Cutscenes")
local triggers = workspace:FindFirstChild("CutsceneTriggers")

-- This script makes CutsceneEvent itself, so do not add one by hand
local cutsceneEvent = Instance.new("RemoteEvent")
cutsceneEvent.Name = "CutsceneEvent"
cutsceneEvent.Parent = ReplicatedStorage

type Shot = { cframe: CFrame, move: number, hold: number, caption: string }

local seen: { [Player]: { [string]: boolean } } = {}
local playing: { [Player]: number } = {} -- the id of the cutscene a player is watching
local lastId = 0

local function secondsAttribute(part: Instance, name: string, default: number): number
	local value = part:GetAttribute(name)
	if typeof(value) == "number" and value >= 0 and value <= 60 then
		return value
	end
	return default
end

-- Shots are parts named 1, 2, 3 ... inside a folder named after the cutscene
local function readShots(name: string): { Shot }
	local shots: { Shot } = {}
	local folder = cutscenes:FindFirstChild(name)
	if not folder then
		warn(`CutsceneService: no folder named {name} in Workspace.Cutscenes`)
		return shots
	end
	for index = 1, MAX_SHOTS do
		local part = folder:FindFirstChild(tostring(index))
		if not (part and part:IsA("BasePart")) then
			break
		end
		local caption = part:GetAttribute("Caption")
		table.insert(shots, {
			cframe = part.CFrame,
			-- the first shot is a cut, so the camera jumps straight to it
			move = if index == 1 then 0 else secondsAttribute(part, "MoveSeconds", DEFAULT_MOVE_SECONDS),
			hold = secondsAttribute(part, "HoldSeconds", DEFAULT_HOLD_SECONDS),
			caption = if typeof(caption) == "string" then caption else "",
		})
	end
	return shots
end

local function setFrozen(player: Player, frozen: boolean)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.Anchored = frozen
	end
end

local function finish(player: Player, id: number)
	if playing[player] ~= id then
		return -- this cutscene already ended
	end
	playing[player] = nil
	setFrozen(player, false)
end

local function play(player: Player, name: string): boolean
	if playing[player] then
		return false -- one cutscene at a time
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local shots = readShots(name)
	if #shots == 0 then
		return false
	end

	lastId += 1
	local id = lastId
	playing[player] = id

	-- With instance streaming on, the player's device may not have the area a shot
	-- looks at, and a request only loads an area for a while. Load the first shot's
	-- area now (waiting up to 2 seconds), and each later shot's area 2 seconds before
	-- the camera starts moving to it.
	local function request(position: Vector3)
		pcall(function()
			player:RequestStreamAroundAsync(position, 2)
		end)
	end
	request(shots[1].cframe.Position)
	if playing[player] ~= id or player.Parent ~= Players then
		return false -- the player left while the area loaded
	end

	setFrozen(player, true)
	cutsceneEvent:FireClient(player, id, shots)
	local startsAt = 0 -- seconds from now until the camera starts moving to this shot
	for index, shot in shots do
		if index > 1 then
			task.delay(math.max(startsAt - 2, 0), function()
				if playing[player] == id then
					request(shot.cframe.Position)
				end
			end)
		end
		startsAt += shot.move + shot.hold
	end
	-- Safety net: unfreeze the player even if their device never reports back
	task.delay(startsAt + 2, finish, player, id)
	return true
end

-- Returns true only when the cutscene started for this player
local function playOnce(player: Player, name: string): boolean
	local playerSeen = seen[player]
	if not playerSeen or playerSeen[name] then
		return false
	end
	if play(player, name) then
		playerSeen[name] = true
		return true
	end
	return false
end

-- The player's device reports that the cutscene ended or was skipped
cutsceneEvent.OnServerEvent:Connect(function(player: Player, id: unknown)
	if typeof(id) == "number" then
		finish(player, id)
	end
end)

-- Trigger parts: touching one plays the cutscene named in its Cutscene attribute
if triggers then
	for _, trigger in triggers:GetChildren() do
		if not trigger:IsA("BasePart") then
			continue
		end
		if not trigger.CanTouch then
			-- Connecting Touched on a part with CanTouch off throws an error, so warn instead
			warn(`CutsceneService: tick CanTouch on {trigger:GetFullName()} so it can start a cutscene`)
			continue
		end
		trigger.Touched:Connect(function(otherPart: BasePart)
			local name = trigger:GetAttribute("Cutscene")
			local character = otherPart:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player and typeof(name) == "string" then
				playOnce(player, name)
			end
		end)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart", 10)
	if playing[player] then
		setFrozen(player, true) -- respawned during a cutscene, so hold the new character still too
	elseif INTRO_CUTSCENE ~= "" then
		playOnce(player, INTRO_CUTSCENE)
	end
end

local function onPlayerAdded(player: Player)
	if seen[player] then
		return -- already set up
	end
	seen[player] = {}
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
	local character = player.Character
	if character then
		task.spawn(onCharacterAdded, player, character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- anyone who joined while this script waited for Cutscenes
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	seen[player] = nil
	playing[player] = nil
end)
