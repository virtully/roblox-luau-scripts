--!strict
-- How to make a drivable car in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-car-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CarSpawner
-- Script in ServerScriptService named CarSpawner.
-- Builds a drivable car from parts and constraints when a player uses the
-- "Spawn car" prompt on Workspace.CarPad. One car per player.
local Players = game:GetService("Players")

local TOP_SPEED = 60 -- studs per second
local REVERSE_SPEED = 25
local DRIVE_TORQUE = 6000 -- how hard the wheels push
local BRAKE_TORQUE = 600 -- slows the car down when you let go
local STEER_ANGLE = 30 -- degrees the front wheels turn
local WHEEL_RADIUS = 1.4

local pad = workspace:WaitForChild("CarPad") :: BasePart
local cars: { [Player]: Model } = {}

local function newPart(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- An attachment whose X axis (the hinge axis) points along worldCFrame's X axis
local function attach(part: BasePart, name: string, worldCFrame: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = part.CFrame:ToObjectSpace(worldCFrame)
	a.Parent = part
	return a
end

type Wheel = { drive: HingeConstraint, steer: HingeConstraint? }

local function buildCar(at: CFrame): (Model, VehicleSeat, BasePart, { Wheel })
	local car = Instance.new("Model")
	car.Name = "Car"
	local R, U, F = at.RightVector, at.UpVector, at.LookVector

	-- The chassis: everything else hangs off this part
	local base = newPart("Base", Vector3.new(6, 1, 10), at * CFrame.new(0, WHEEL_RADIUS + 0.5, 0), car)
	base.Color = Color3.fromRGB(200, 40, 50)
	car.PrimaryPart = base

	local body = newPart("Body", Vector3.new(5.6, 2, 5), at * CFrame.new(0, WHEEL_RADIUS + 2, 1), car)
	body.Color = Color3.fromRGB(230, 60, 70)
	body.Massless = true
	weld(base, body)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = at * CFrame.new(0, WHEEL_RADIUS + 1.5, -2)
	seat.HeadsUpDisplay = false
	seat.Massless = true
	seat.Parent = car
	weld(base, seat)

	local wheels: { Wheel } = {}
	for _, corner in { Vector3.new(-3.6, 0, -3.5), Vector3.new(3.6, 0, -3.5), Vector3.new(-3.6, 0, 3.5), Vector3.new(3.6, 0, 3.5) } do
		local front = corner.Z < 0 -- the car faces -Z, the pad's look direction
		local pos = at:PointToWorldSpace(Vector3.new(corner.X, WHEEL_RADIUS, corner.Z))

		local wheel = newPart("Wheel", Vector3.new(1, WHEEL_RADIUS * 2, WHEEL_RADIUS * 2), CFrame.fromMatrix(pos, R, U), car)
		wheel.Shape = Enum.PartType.Cylinder -- a cylinder's round faces are on its X axis
		wheel.Color = Color3.fromRGB(30, 30, 34)
		wheel.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1.5, 0, 100, 1)

		local hub: BasePart = base
		local steer: HingeConstraint? = nil
		if front then
			-- Front wheels turn on a small knuckle part, steered by a servo hinge with an up axis
			local knuckle = newPart("Knuckle", Vector3.new(0.5, 0.5, 0.5), CFrame.fromMatrix(pos, R, U), car)
			knuckle.CanCollide = false
			knuckle.Transparency = 1
			knuckle.Massless = true
			local axisUp = CFrame.fromMatrix(pos, U, F)
			local servo = Instance.new("HingeConstraint")
			servo.Attachment0 = attach(base, "SteerBase", axisUp)
			servo.Attachment1 = attach(knuckle, "SteerKnuckle", axisUp)
			servo.ActuatorType = Enum.ActuatorType.Servo
			servo.ServoMaxTorque = 20000
			servo.AngularSpeed = 5
			servo.LimitsEnabled = true
			servo.LowerAngle = -STEER_ANGLE
			servo.UpperAngle = STEER_ANGLE
			servo.Parent = knuckle
			hub = knuckle
			steer = servo
		end

		-- Every wheel spins on a motor hinge whose axis points to the car's left:
		-- a positive AngularVelocity about that axis rolls the wheel forward
		local axisLeft = CFrame.fromMatrix(pos, -R, U)
		local drive = Instance.new("HingeConstraint")
		drive.Attachment0 = attach(hub, "DriveHub", axisLeft)
		drive.Attachment1 = attach(wheel, "DriveWheel", axisLeft)
		drive.ActuatorType = Enum.ActuatorType.Motor
		drive.MotorMaxTorque = BRAKE_TORQUE
		drive.AngularVelocity = 0
		drive.Parent = wheel

		table.insert(wheels, { drive = drive, steer = steer })
	end
	return car, seat, base, wheels
end

-- Reads the driver's keys (W/S or the thumbstick) from the seat and turns them into wheel motion
local function wireControls(seat: VehicleSeat, base: BasePart, wheels: { Wheel })
	local function update()
		local throttle = seat.ThrottleFloat
		local speed = if throttle > 0 then TOP_SPEED * throttle else REVERSE_SPEED * throttle
		for _, w in wheels do
			w.drive.AngularVelocity = speed / WHEEL_RADIUS
			w.drive.MotorMaxTorque = if throttle == 0 then BRAKE_TORQUE else DRIVE_TORQUE
			if w.steer then
				-- SteerFloat is 1 for right (D); a positive servo angle about the up axis turns left
				w.steer.TargetAngle = -seat.SteerFloat * STEER_ANGLE
			end
		end
	end
	seat:GetPropertyChangedSignal("ThrottleFloat"):Connect(update)
	seat:GetPropertyChangedSignal("SteerFloat"):Connect(update)

	-- The driver's computer simulates the car, so it reacts without lag
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local humanoid = seat.Occupant
		local character = humanoid and humanoid.Parent
		local driver = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
		if driver then
			base:SetNetworkOwner(driver)
		elseif base:IsDescendantOf(workspace) then
			base:SetNetworkOwnershipAuto()
			update()
		end
	end)
end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Spawn car"
prompt.ObjectText = "Car"
prompt.RequiresLineOfSight = false
prompt.Parent = pad

prompt.Triggered:Connect(function(player: Player)
	local old = cars[player]
	if old then
		old:Destroy()
	end
	-- the car appears in front of the pad, facing the same way as the pad
	local spawnAt = pad.CFrame * CFrame.new(0, pad.Size.Y / 2, -12)
	local car, seat, base, wheels = buildCar(spawnAt)
	car.Parent = workspace
	cars[player] = car
	wireControls(seat, base, wheels)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local car = cars[player]
	if car then
		car:Destroy()
		cars[player] = nil
	end
end)
