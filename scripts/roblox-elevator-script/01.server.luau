--!strict
-- How to make an elevator in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-elevator-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Elevator Model named ElevatorScript
-- Script inside the Elevator Model, named ElevatorScript.
-- Moves the Car between the parts in Stops when a button with a Floor attribute is clicked.
local SPEED = 10 -- studs per second
local DOOR_WAIT = 3 -- seconds to wait at each floor
local DEPART_DELAY = 1 -- seconds between closing the doors and moving
local LIT_COLOR = Color3.fromRGB(255, 200, 60)

local elevator = script.Parent :: Model
local car = elevator:WaitForChild("Car") :: BasePart
local stopsFolder = elevator:WaitForChild("Stops")

-- Floor number to the point the car's centre goes to
local stops: { [number]: Vector3 } = {}
for _, stop in stopsFolder:GetChildren() do
	local floor = tonumber(stop.Name)
	if floor and stop:IsA("BasePart") then
		stops[floor] = stop.Position
	end
end

-- Weld everything inside the car (walls, inside buttons) so it moves with it
for _, part in car:GetDescendants() do
	if part:IsA("BasePart") then
		part.Anchored = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = car
		weld.Part1 = part
		weld.Parent = part
	end
end

-- The car is moved by physics, so players standing on it are carried
car.Anchored = false
local attachment = Instance.new("Attachment")
attachment.Parent = car

local mover = Instance.new("AlignPosition")
mover.Mode = Enum.PositionAlignmentMode.OneAttachment
mover.Attachment0 = attachment
mover.Position = car.Position
mover.MaxVelocity = SPEED
mover.MaxForce = math.huge
mover.Responsiveness = 200
mover.Parent = car

local holder = Instance.new("AlignOrientation")
holder.Mode = Enum.OrientationAlignmentMode.OneAttachment
holder.Attachment0 = attachment
holder.CFrame = car.CFrame.Rotation
holder.MaxTorque = math.huge
holder.Responsiveness = 200
holder.Parent = car

-- The server simulates the car, so it does not jump when a player steps in
car:SetNetworkOwner(nil)

-- Find the floor the car starts at: the closest stop
local currentFloor = 1
local closest = math.huge
for floor, position in stops do
	local distance = (position - car.Position).Magnitude
	if distance < closest then
		closest = distance
		currentFloor = floor
	end
end
elevator:SetAttribute("CurrentFloor", currentFloor)

-- Buttons: every part in the Model with a number attribute "Floor"
local buttons: { BasePart } = {}
local normalColors: { [BasePart]: Color3 } = {}
local normalMaterials: { [BasePart]: Enum.Material } = {}

local function lightButtons(floor: number, on: boolean)
	for _, button in buttons do
		if button:GetAttribute("Floor") == floor then
			button.Color = if on then LIT_COLOR else normalColors[button]
			button.Material = if on then Enum.Material.Neon else normalMaterials[button]
		end
	end
end

local queue: { number } = {}
local running = false

local function moveTo(floor: number)
	local stop = stops[floor]
	if not stop then
		return
	end
	-- CurrentFloor 0 means "moving": doors close, then the car leaves
	elevator:SetAttribute("CurrentFloor", 0)
	task.wait(DEPART_DELAY)
	-- Keep the car's own X and Z, so a stop placed slightly off-centre cannot pull it sideways
	local target = Vector3.new(car.Position.X, stop.Y, car.Position.Z)
	mover.Position = target
	local started = os.clock()
	local timeout = (target - car.Position).Magnitude / SPEED + 5
	while (car.Position - target).Magnitude > 0.2 and os.clock() - started < timeout do
		task.wait(0.1)
	end
	currentFloor = floor
	elevator:SetAttribute("CurrentFloor", floor)
end

local function run()
	running = true
	while #queue > 0 do
		local floor = table.remove(queue, 1) :: number
		moveTo(floor)
		lightButtons(floor, false)
		task.wait(DOOR_WAIT)
	end
	running = false
end

local function request(floor: number)
	if not stops[floor] or table.find(queue, floor) then
		return
	end
	if floor == currentFloor and not running then
		return
	end
	table.insert(queue, floor)
	lightButtons(floor, true)
	if not running then
		task.spawn(run)
	end
end

for _, part in elevator:GetDescendants() do
	local floor = part:GetAttribute("Floor")
	if part:IsA("BasePart") and type(floor) == "number" then
		table.insert(buttons, part)
		normalColors[part] = part.Color
		normalMaterials[part] = part.Material
		local detector = part:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
		detector.MaxActivationDistance = 16
		detector.Parent = part
		detector.MouseClick:Connect(function(_player: Player)
			request(floor)
		end)
	end
end

if next(stops) == nil then
	warn("ElevatorScript: no stop parts named 1, 2, 3... in the Stops folder")
end
