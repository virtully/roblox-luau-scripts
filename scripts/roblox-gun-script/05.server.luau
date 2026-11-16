--!strict
-- How to make a gun in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gun-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LauncherService
-- Script in ServerScriptService named LauncherService.
-- A slow, falling rocket that the server launches, moves and checks itself.
-- The client sends only the aim point, exactly like the blaster.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Settings
local LAUNCHER_NAME = "Launcher" -- the Tool's name in StarterPack
local FIRE_INTERVAL = 1.2 -- seconds between rockets; keep the same value in GunTrigger
local NETWORK_SLACK = 0.05
local SPEED = 90 -- studs per second at launch
local GRAVITY_SCALE = 0.25 -- how much of workspace.Gravity pulls the rocket down (0: a straight line)
local MAX_LIFETIME = 4 -- seconds before a rocket that hit nothing is removed
local DIRECT_DAMAGE = 40 -- extra damage to the character the rocket hits
local BLAST_RADIUS = 8 -- studs
local BLAST_DAMAGE = 30 -- at the centre of the blast, falling to 0 at its edge
local FRIENDLY_FIRE = false

local fireEvent = Instance.new("RemoteEvent")
fireEvent.Name = "LauncherFire"
fireEvent.Parent = ReplicatedStorage

type Rocket = {
	part: BasePart,
	velocity: Vector3,
	age: number,
	shooter: Player,
	params: RaycastParams,
}

local rockets: { Rocket } = {}
local lastShot: { [Player]: number } = {}

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

local function damage(humanoid: Humanoid, amount: number, shooter: Player)
	local model = humanoid.Parent
	if amount <= 0 or humanoid.Health <= 0 or not (model and model:IsA("Model")) then
		return
	end
	if not isTeammate(shooter, Players:GetPlayerFromCharacter(model)) then
		humanoid:TakeDamage(amount)
	end
end

local function explode(rocket: Rocket, result: RaycastResult)
	local shooterCharacter = rocket.shooter.Character
	-- Start the blast a little off the surface, so the wall it hit does not block it
	local centre = result.Position + result.Normal * 0.5

	-- 1. Direct hit: the character the rocket flew into
	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
	local directTarget = hitModel and hitModel:FindFirstChildOfClass("Humanoid")
	if directTarget and hitModel ~= shooterCharacter then
		damage(directTarget, DIRECT_DAMAGE, rocket.shooter)
	end

	-- 2. Splash: every other Humanoid near the blast, less the further away it is
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = if shooterCharacter then { shooterCharacter } else {}
	local seen: { [Humanoid]: boolean } = {}
	for _, part in workspace:GetPartBoundsInRadius(centre, BLAST_RADIUS, overlap) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if model and humanoid and root and not seen[humanoid] then
			seen[humanoid] = true
			-- A wall between the blast and the character shields it
			local wallParams = RaycastParams.new()
			wallParams.ExcludeInstances = { model }
			local toRoot = root.Position - centre
			if not workspace:Raycast(centre, toRoot, wallParams) then
				local falloff = 1 - math.clamp(toRoot.Magnitude / BLAST_RADIUS, 0, 1)
				damage(humanoid, math.floor(BLAST_DAMAGE * falloff), rocket.shooter)
			end
		end
	end
end

fireEvent.OnServerEvent:Connect(function(player: Player, aimPoint: unknown)
	if typeof(aimPoint) ~= "Vector3" or aimPoint ~= aimPoint then
		return
	end
	local now = os.clock()
	local last = lastShot[player]
	if last and now - last < FIRE_INTERVAL - NETWORK_SLACK then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and humanoid) or humanoid.Health <= 0 then
		return
	end
	local launcher = character:FindFirstChild(LAUNCHER_NAME)
	local handle = launcher and launcher:FindFirstChild("Handle")
	if not (launcher and launcher:IsA("Tool") and handle and handle:IsA("BasePart")) then
		return
	end
	local origin = handle.Position
	local offset = aimPoint - origin
	if offset.Magnitude < 0.5 or offset.Magnitude > 100000 then
		return
	end
	local params = RaycastParams.new()
	params.ExcludeInstances = { character }
	-- The same wall check as the blaster: no firing from the far side of a thin wall
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and workspace:Raycast(root.Position, origin - root.Position, params) then
		return
	end
	lastShot[player] = now

	-- The rocket is only a picture: the server's raycasts decide what it hits
	local part = Instance.new("Part")
	part.Name = "Rocket"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.8, 0.8, 0.8)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 140, 60)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(origin)
	part.Parent = workspace

	local rocket: Rocket = {
		part = part :: BasePart,
		velocity = offset.Unit * SPEED,
		age = 0,
		shooter = player,
		params = params,
	}
	table.insert(rockets, rocket)
end)

-- Every frame: move each rocket one step, and cast a ray along that step
RunService.Heartbeat:Connect(function(deltaTime: number)
	local gravity = Vector3.new(0, -workspace.Gravity * GRAVITY_SCALE, 0)
	for i = #rockets, 1, -1 do
		local rocket = rockets[i]
		rocket.age += deltaTime
		local from = rocket.part.Position
		local step = rocket.velocity * deltaTime + gravity * (0.5 * deltaTime * deltaTime)
		rocket.velocity += gravity * deltaTime
		local result = workspace:Raycast(from, step, rocket.params)
		if result then
			explode(rocket, result)
		end
		if result or rocket.age >= MAX_LIFETIME then
			rocket.part:Destroy()
			table.remove(rockets, i)
		else
			rocket.part.CFrame = CFrame.new(from + step)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastShot[player] = nil
end)
