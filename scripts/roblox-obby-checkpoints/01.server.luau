--!strict
-- How to make obby checkpoints in Roblox Studio (with saving)
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-obby-checkpoints
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ObbyCheckpoints
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Settings
local ALLOW_SKIPPING = false -- true: touching any later checkpoint moves a player there
local RESPAWN_DELAY = 2 -- seconds between dying and respawning
local SPAWN_HEIGHT = 3 -- studs from the top of the checkpoint to the character's root part
local AUTOSAVE_SECONDS = 60
local MAX_SAVED_PURCHASES = 50 -- skip-stage receipts remembered per player
-- In Studio a failed load gives up at once, so testing without data store access is quick
local LOAD_ATTEMPTS = if RunService:IsStudio() then 1 else 3
local STORE_NAME = "ObbyStage_v1"

-- Called inside each pcall below, so a place without data store access
-- still runs everything else in this script
local function stageStore(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

-- 1. Find the checkpoints: parts named 1, 2, 3... in a Workspace folder named
-- Checkpoints, or parts in Workspace with the tag Checkpoint and a number attribute Stage.
local checkpoints: { [number]: BasePart } = {}

local function addCheckpoint(instance: Instance, stage: number?)
	if not instance:IsA("BasePart") or not instance:IsDescendantOf(workspace) then
		return -- skips tagged templates kept in ServerStorage or ReplicatedStorage
	end
	if not stage or stage < 1 or stage % 1 ~= 0 then
		return
	end
	local existing = checkpoints[stage]
	if existing and existing ~= instance then
		warn(`Two checkpoints use stage {stage}: {existing:GetFullName()} and {instance:GetFullName()}`)
		return
	end
	checkpoints[stage] = instance
end

local folder = workspace:FindFirstChild("Checkpoints")
if folder then
	for _, child in folder:GetChildren() do
		addCheckpoint(child, tonumber(child.Name))
	end
end
for _, tagged in CollectionService:GetTagged("Checkpoint") do
	local stage = tagged:GetAttribute("Stage")
	addCheckpoint(tagged, if type(stage) == "number" then stage else nil)
end

-- Stages must run 1, 2, 3... with no gaps; anything after a gap can never be reached
local lastStage = 0
while checkpoints[lastStage + 1] do
	lastStage += 1
end
assert(lastStage > 0, "No checkpoint 1: add a part named 1 to Workspace.Checkpoints")
for stage in checkpoints do
	if stage > lastStage then
		warn(`Checkpoint {stage} can never be reached: there is no checkpoint {lastStage + 1}`)
	end
end
workspace:SetAttribute("ObbyLastStage", lastStage) -- read by the optional skip button

-- From here on this script spawns every character itself, so each one appears at its stage
Players.CharacterAutoLoads = false

-- 2. Player state, kept on the server only
local stageValues: { [Player]: IntValue } = {} -- the Stage value in each player's leaderstats
local savedStages: { [Player]: number } = {} -- the stage this server last saved or loaded
local pendingSaves = 0

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- 3. Spawning
local function spawnCFrame(part: BasePart): CFrame
	local _, yaw = part.CFrame:ToOrientation()
	local position = part.Position + Vector3.new(0, part.Size.Y / 2 + SPAWN_HEIGHT, 0)
	return CFrame.new(position) * CFrame.Angles(0, yaw, 0)
end

local spawnAtStage: (player: Player) -> ()

local function watchCharacter(player: Player, character: Model)
	local respawning = false
	local function respawnLater()
		if respawning then
			return
		end
		respawning = true
		task.wait(RESPAWN_DELAY)
		-- Only respawn if they are still here and nothing has spawned them since
		if player.Parent and player.Character == character then
			spawnAtStage(player)
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(respawnLater)
	end
	-- Falling off the map can remove the character from Workspace, and Died only
	-- fires while the Humanoid is in Workspace, so this catches that case too
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			respawnLater()
		end
	end)
end

spawnAtStage = function(player: Player)
	local oldCharacter = player.Character
	local ok, err = pcall(function()
		player:LoadCharacterAsync()
	end)
	if not ok then
		warn(`Could not spawn {player.Name}: {err}`)
		-- Try again shortly, unless they have left or have been spawned since
		task.delay(RESPAWN_DELAY, function()
			if player.Parent and stageValues[player] and player.Character == oldCharacter then
				spawnAtStage(player)
			end
		end)
		return
	end
	if oldCharacter and oldCharacter ~= player.Character then
		oldCharacter:Destroy() -- releases the old character's connections
	end
	local character = player.Character
	local stageValue = stageValues[player]
	if not (character and stageValue) then
		return
	end
	-- Move the character only after LoadCharacterAsync has placed it
	character:PivotTo(spawnCFrame(checkpoints[stageValue.Value]))
	watchCharacter(player, character)
end

-- 4. Touching checkpoints
local function onCheckpointTouched(stage: number, hit: BasePart)
	-- FindFirstAncestorOfClass also finds the character when an accessory or tool touches
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not (character and player) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return -- a dead character falling onto a checkpoint does not count
	end
	local stageValue = stageValues[player]
	if not stageValue then
		return -- their saved stage has not loaded yet
	end

	local current = stageValue.Value
	-- The next stage only. Touching the current or an earlier checkpoint does nothing,
	-- so however many times Touched fires, the stage goes up once.
	if stage == current + 1 or (ALLOW_SKIPPING and stage > current) then
		stageValue.Value = stage
	end
end

for stage = 1, lastStage do
	checkpoints[stage].Touched:Connect(function(hit)
		onCheckpointTouched(stage, hit)
	end)
end

-- 5. Loading and saving
local function loadStage(player: Player): number
	for attempt = 1, LOAD_ATTEMPTS do
		local ok, data = pcall(function()
			return stageStore():GetAsync(keyFor(player))
		end)
		if ok then
			local saved = if type(data) == "table" then tonumber(data.Stage) else nil
			return if saved then math.floor(saved) else 1
		end
		warn(`Could not load {player.Name}'s stage (attempt {attempt} of {LOAD_ATTEMPTS}): {data}`)
		if attempt < LOAD_ATTEMPTS then
			task.wait(attempt * 2)
		end
	end
	-- Start at stage 1. The save below never lowers a saved stage, so this cannot wipe progress.
	return 1
end

local function saveStage(player: Player)
	local stageValue = stageValues[player]
	if not stageValue then
		return
	end
	local stage = stageValue.Value
	if stage <= (savedStages[player] or 0) then
		return -- nothing new since the last save
	end

	pendingSaves += 1
	local ok, err = pcall(function()
		stageStore():UpdateAsync(keyFor(player), function(old)
			local data: { [string]: any } = if type(old) == "table" then old else {}
			if (tonumber(data.Stage) or 0) >= stage then
				return nil -- the saved stage is already this far: cancel the write
			end
			data.Stage = stage
			return data
		end)
	end)
	pendingSaves -= 1

	if ok and stageValues[player] then
		savedStages[player] = math.max(savedStages[player] or 0, stage)
	elseif not ok then
		warn(`Could not save {player.Name}'s stage: {err}`)
	end
end

-- 6. Players joining and leaving
local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Parent = leaderstats

	local stage = math.clamp(loadStage(player), 1, lastStage)
	if not player.Parent then
		return -- they left while their stage was loading
	end
	stageValue.Value = stage
	savedStages[player] = stage
	stageValues[player] = stageValue
	leaderstats.Parent = player

	spawnAtStage(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local character = player.Character
	saveStage(player)
	stageValues[player] = nil
	savedStages[player] = nil
	-- Destroying the character disconnects the Died and AncestryChanged
	-- connections from section 3, whatever PlayerCharacterDestroyBehavior is set to
	if character then
		character:Destroy()
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in Players:GetPlayers() do
			task.spawn(saveStage, player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(saveStage, player)
	end
	-- Wait for every save, including ones started by PlayerRemoving
	while pendingSaves > 0 do
		task.wait()
	end
end)

-- 7. Hook for the optional skip-stage developer product (see the guide).
-- Returns true once the skip is saved, or was already saved by any server.
local skipStage = Instance.new("BindableFunction")
skipStage.Name = "SkipStage"
skipStage.Parent = ServerStorage

skipStage.OnInvoke = function(player: Player, purchaseId: string): boolean
	-- A receipt can arrive while the player is still joining: wait for their stage
	while player.Parent and not stageValues[player] do
		task.wait(0.5)
	end
	local stageValue = stageValues[player]
	if not stageValue then
		return false -- they left; Roblox runs ProcessReceipt again when they rejoin
	end

	local newStage = stageValue.Value
	pendingSaves += 1
	local ok, err = pcall(function()
		stageStore():UpdateAsync(keyFor(player), function(old)
			local data: { [string]: any } = if type(old) == "table" then old else {}
			local purchases: { string } = if type(data.Purchases) == "table" then data.Purchases else {}
			newStage = math.max(tonumber(data.Stage) or 1, stageValue.Value)
			if table.find(purchases, purchaseId) then
				return nil -- already granted: change nothing
			end
			newStage = math.min(newStage + 1, lastStage)
			table.insert(purchases, purchaseId)
			if #purchases > MAX_SAVED_PURCHASES then
				table.remove(purchases, 1)
			end
			data.Stage = newStage
			data.Purchases = purchases
			return data
		end)
	end)
	pendingSaves -= 1
	if not ok then
		warn(`Could not save a stage skip for {player.Name}: {err}`)
		return false
	end
	if stageValues[player] ~= stageValue then
		return true -- saved, but they have left: the new stage loads next time
	end

	newStage = math.min(newStage, lastStage)
	savedStages[player] = math.max(savedStages[player] or 0, newStage)
	if newStage > stageValue.Value then
		stageValue.Value = newStage
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health > 0 then
			character:PivotTo(spawnCFrame(checkpoints[newStage]))
		end
	end
	return true
end
