--!strict
-- How to make a game like Steal a Brainrot in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-steal-a-brainrot-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named StealGame
-- Script in ServerScriptService named StealGame.
-- The whole loop on the server: conveyor, buying, income, stealing, locks and saving.
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

type UnitInfo = { name: string, price: number, income: number, weight: number, color: Color3 }

-- Your units: price to buy, cash per second once owned, and how often they show up
local UNITS: { UnitInfo } = {
	{ name = "Pebble Pal", price = 25, income = 1, weight = 50, color = Color3.fromRGB(160, 160, 170) },
	{ name = "Toast Buddy", price = 150, income = 5, weight = 30, color = Color3.fromRGB(230, 170, 90) },
	{ name = "Cactus Chef", price = 900, income = 25, weight = 14, color = Color3.fromRGB(90, 190, 100) },
	{ name = "Disco Moon", price = 6000, income = 120, weight = 5, color = Color3.fromRGB(150, 110, 255) },
	{ name = "Golden Noodle", price = 40000, income = 700, weight = 1, color = Color3.fromRGB(255, 210, 60) },
}
local START_CASH = 100
local SPAWN_EVERY = 2.5 -- seconds between units on the conveyor
local BELT_SPEED = 8 -- studs per second
local STEAL_HOLD = 1.5 -- seconds a thief holds the prompt
local LOCK_SECONDS = 30
local STORE = DataStoreService:GetDataStore("StealGame_v1")

local bases = workspace:WaitForChild("Bases") :: Folder
local conveyor = workspace:WaitForChild("Conveyor") :: Folder
local beltStart = conveyor:WaitForChild("Start") :: BasePart
local beltEnd = conveyor:WaitForChild("End") :: BasePart
local templates = ReplicatedStorage:FindFirstChild("Units") -- optional models named like the units

type PlayerState = {
	base: Model,
	slots: { [number]: string }, -- slot number -> unit name
	lockedUntil: number,
	carrying: Model?, -- a unit this player stole and has not brought home yet
	carriedFrom: Player?,
	carriedName: string?,
}
local states: { [Player]: PlayerState } = {}

local function findUnit(name: string): UnitInfo?
	for _, info in UNITS do
		if info.name == name then
			return info
		end
	end
	return nil
end

local function slotPart(base: Model, index: number): BasePart?
	local slots = base:FindFirstChild("Slots")
	local slot = slots and slots:FindFirstChild("Slot" .. index)
	return if slot and slot:IsA("BasePart") then slot else nil
end

local function slotCount(base: Model): number
	local slots = base:FindFirstChild("Slots")
	return if slots then #slots:GetChildren() else 0
end

local function freeSlot(state: PlayerState): number?
	for i = 1, slotCount(state.base) do
		if state.slots[i] == nil then
			return i
		end
	end
	return nil
end

local function cashOf(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	return if cash and cash:IsA("IntValue") then cash else nil
end

-- A unit's model: your template from ReplicatedStorage.Units, or a coloured block
local function makeModel(info: UnitInfo): Model
	local template = templates and templates:FindFirstChild(info.name)
	if template and template:IsA("Model") then
		local copy = template:Clone()
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		return copy
	end
	local model = Instance.new("Model")
	model.Name = info.name
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 3)
	body.Color = info.color
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	return model
end

local function addPrompt(model: Model, action: string, object: string, hold: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	return prompt
end

local function isLocked(state: PlayerState): boolean
	return os.clock() < state.lockedUntil
end

local placeUnit: (owner: Player, index: number, name: string) -> ()

-- A thief picks up a unit from someone else's base
local function startSteal(thief: Player, owner: Player, index: number, display: Model)
	local thiefState, ownerState = states[thief], states[owner]
	if not thiefState or not ownerState or thief == owner then
		return
	end
	local name = ownerState.slots[index]
	if not name or isLocked(ownerState) or thiefState.carrying then
		return
	end
	ownerState.slots[index] = nil
	display:Destroy()
	local info = findUnit(name)
	if not info then
		return
	end
	local carried = makeModel(info)
	carried.Parent = workspace
	thiefState.carrying = carried
	thiefState.carriedFrom = owner
	thiefState.carriedName = name
end

-- Puts a unit on a base's slot, with a Steal prompt for everyone but the owner
placeUnit = function(owner: Player, index: number, name: string)
	local state = states[owner]
	local info = findUnit(name)
	local slot = state and slotPart(state.base, index)
	if not state or not info or not slot then
		return
	end
	state.slots[index] = name
	local model = makeModel(info)
	model:SetAttribute("Slot", index)
	model:PivotTo(slot.CFrame * CFrame.new(0, 2.5, 0))
	model.Parent = slot
	local prompt = addPrompt(model, "Steal", name, STEAL_HOLD)
	prompt.Enabled = not isLocked(state)
	prompt.Triggered:Connect(function(thief: Player)
		startSteal(thief, owner, index, model)
	end)
end

-- The thief is gone or died: the unit goes back to its owner if there is room
local function dropCarried(thief: Player)
	local state = states[thief]
	if not state or not state.carrying then
		return
	end
	state.carrying:Destroy()
	local owner, name = state.carriedFrom, state.carriedName
	state.carrying, state.carriedFrom, state.carriedName = nil, nil, nil
	local ownerState = owner and states[owner]
	if owner and ownerState and name then
		local index = freeSlot(ownerState)
		if index then
			placeUnit(owner, index, name)
		end
	end
end

-- The thief reached their own Home pad with the unit
local function deliver(thief: Player)
	local state = states[thief]
	if not state or not state.carrying or not state.carriedName then
		return
	end
	local index = freeSlot(state)
	if not index then
		return -- base full: they keep carrying it until a slot frees up
	end
	local name = state.carriedName
	state.carrying:Destroy()
	state.carrying, state.carriedFrom, state.carriedName = nil, nil, nil
	placeUnit(thief, index, name)
end

local function setLock(state: PlayerState, locked: boolean)
	local barrier = state.base:FindFirstChild("Barrier")
	if barrier and barrier:IsA("BasePart") then
		barrier.CanCollide = locked
		barrier.Transparency = if locked then 0.4 else 1
	end
	-- Steal prompts are off while the base is locked (the server checks again anyway)
	for _, d in state.base:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.ActionText == "Steal" then
			d.Enabled = not locked
		end
	end
end

-- Each base gets two collision groups: its barrier never blocks its owner
local function ownerGroup(base: Model): string
	return base.Name .. "_Owner"
end

-- Wire up each base's Home pad, barrier and lock button once
for _, base in bases:GetChildren() do
	if not base:IsA("Model") then
		continue
	end
	local barrierGroup = base.Name .. "_Barrier"
	PhysicsService:RegisterCollisionGroup(barrierGroup)
	PhysicsService:RegisterCollisionGroup(ownerGroup(base))
	PhysicsService:CollisionGroupSetCollidable(barrierGroup, ownerGroup(base), false)
	local barrierPart = base:FindFirstChild("Barrier")
	if barrierPart and barrierPart:IsA("BasePart") then
		barrierPart.CollisionGroup = barrierGroup
	end
	local home = base:FindFirstChild("Home")
	if home and home:IsA("BasePart") then
		home.Touched:Connect(function(hit: BasePart)
			local character = hit.Parent
			local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
			local state = player and states[player]
			if player and state and state.base == base then
				deliver(player)
			end
		end)
	end
	local button = base:FindFirstChild("LockButton")
	if button and button:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Lock base"
		prompt.ObjectText = LOCK_SECONDS .. " seconds"
		prompt.RequiresLineOfSight = false
		prompt.Parent = button
		prompt.Triggered:Connect(function(player: Player)
			local state = states[player]
			if not state or state.base ~= base or isLocked(state) then
				return -- only the owner, and not while already locked
			end
			state.lockedUntil = os.clock() + LOCK_SECONDS
			setLock(state, true)
			task.delay(LOCK_SECONDS, function()
				if states[player] == state then
					setLock(state, false)
				end
			end)
		end)
	end
end

-- Saving: cash and the unit on each slot
local function save(player: Player)
	local state, cash = states[player], cashOf(player)
	if not state or not cash then
		return
	end
	local units: { string } = {}
	for i = 1, slotCount(state.base) do
		units[i] = state.slots[i] or ""
	end
	local ok, err = pcall(function()
		STORE:SetAsync("player_" .. player.UserId, { cash = cash.Value, units = units })
	end)
	if not ok then
		warn("StealGame save failed for", player.Name, err)
	end
end

local function onPlayerAdded(player: Player)
	local base: Model? = nil
	for _, b in bases:GetChildren() do
		if b:IsA("Model") and b:GetAttribute("OwnerId") == nil then
			base = b
			break
		end
	end
	if not base then
		player:Kick("This server is full. Please join another server.")
		return
	end
	base:SetAttribute("OwnerId", player.UserId)
	base:SetAttribute("OwnerName", player.DisplayName)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = START_CASH
	cash.Parent = stats
	stats.Parent = player

	local state: PlayerState = { base = base, slots = {}, lockedUntil = 0 }
	states[player] = state

	local ok, data = pcall(function()
		return STORE:GetAsync("player_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		cash.Value = tonumber(data.cash) or START_CASH
		if type(data.units) == "table" then
			for i, name in data.units do
				if type(i) == "number" and type(name) == "string" and findUnit(name) then
					placeUnit(player, i, name)
				end
			end
		end
	end

	local function onCharacter(character: Model)
		-- the owner walks through their own barrier
		local function joinGroup(d: Instance)
			if d:IsA("BasePart") then
				d.CollisionGroup = ownerGroup(base)
			end
		end
		for _, d in character:GetDescendants() do
			joinGroup(d)
		end
		character.DescendantAdded:Connect(joinGroup)
		local home = base:FindFirstChild("Home")
		if home and home:IsA("BasePart") then
			task.defer(function()
				character:PivotTo(home.CFrame * CFrame.new(0, 4, 0))
			end)
		end
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			dropCarried(player)
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	dropCarried(player)
	save(player)
	local state = states[player]
	if state then
		for _, d in state.base:GetDescendants() do
			if d:IsA("Model") and d:GetAttribute("Slot") then
				d:Destroy()
			end
		end
		setLock(state, false)
		state.base:SetAttribute("OwnerId", nil)
		state.base:SetAttribute("OwnerName", nil)
	end
	-- anyone carrying this player's units keeps them
	states[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		save(player)
	end
end)

-- Income: every owned unit pays its owner once a second
task.spawn(function()
	while true do
		task.wait(1)
		for player, state in states do
			local cash = cashOf(player)
			if cash then
				local total = 0
				for _, name in state.slots do
					local info = findUnit(name)
					total += if info then info.income else 0
				end
				cash.Value += total
			end
		end
	end
end)

-- The conveyor: a random unit every SPAWN_EVERY seconds, rarer ones less often
local totalWeight = 0
for _, info in UNITS do
	totalWeight += info.weight
end

local function pickUnit(): UnitInfo
	local roll = math.random() * totalWeight
	for _, info in UNITS do
		roll -= info.weight
		if roll <= 0 then
			return info
		end
	end
	return UNITS[1]
end

type Rider = { model: Model, info: UnitInfo, distance: number }
local riders: { Rider } = {}
local beltLength = (beltEnd.Position - beltStart.Position).Magnitude
local beltDirection = (beltEnd.Position - beltStart.Position).Unit

local function spawnRider()
	local info = pickUnit()
	local model = makeModel(info)
	model:PivotTo(CFrame.new(beltStart.Position + Vector3.new(0, 2.5, 0)))
	model.Parent = conveyor
	local rider: Rider = { model = model, info = info, distance = 0 }
	table.insert(riders, rider)
	local prompt = addPrompt(model, "Buy", info.name .. " ($" .. info.price .. ")", 0)
	prompt.Triggered:Connect(function(player: Player)
		local state, cash = states[player], cashOf(player)
		if not state or not cash or model.Parent ~= conveyor then
			return -- someone else bought it first
		end
		local index = freeSlot(state)
		if not index or cash.Value < info.price then
			return
		end
		cash.Value -= info.price
		model:Destroy()
		placeUnit(player, index, info.name)
	end)
end

task.spawn(function()
	while true do
		spawnRider()
		task.wait(SPAWN_EVERY)
	end
end)

RunService.Heartbeat:Connect(function(dt: number)
	-- move the conveyor units, and remove the ones that reached the end or were bought
	for i = #riders, 1, -1 do
		local rider = riders[i]
		rider.distance += BELT_SPEED * dt
		if rider.model.Parent ~= conveyor or rider.distance >= beltLength then
			rider.model:Destroy()
			table.remove(riders, i)
		else
			rider.model:PivotTo(CFrame.new(beltStart.Position + beltDirection * rider.distance + Vector3.new(0, 2.5, 0)))
		end
	end
	-- carried units float over the thief's head
	for player, state in states do
		local carried = state.carrying
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if carried and head and head:IsA("BasePart") then
			carried:PivotTo(head.CFrame * CFrame.new(0, 3.5, 0))
		end
	end
end)
