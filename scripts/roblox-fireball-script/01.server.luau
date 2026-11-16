--!strict
-- How to make a fireball in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fireball-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named FireballService
-- Script in ServerScriptService named FireballService.
-- Checks each cast, then spawns, moves and explodes the fireball. The client only sends an aim point.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TOOL_NAME = "Fireball" -- the Tool the player must be holding
local REQUIRE_TOOL = true -- false for a key ability with no Tool (Step 4)
local COOLDOWN = 1.5 -- seconds between fireballs for one player
local SPEED = 80 -- studs per second
local MAX_RANGE = 300 -- studs before the fireball fizzles out
local DAMAGE = 30 -- health taken by every character inside the blast
local BLAST_RADIUS = 6 -- studs around the impact
local FRIENDLY_FIRE = false

local castEvent = Instance.new("RemoteEvent")
castEvent.Name = "CastFireball"
castEvent.Parent = ReplicatedStorage

local lastCast: { [Player]: number } = {}

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

local function makeBall(position: Vector3): Part
	local ball = Instance.new("Part")
	ball.Name = "Fireball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 120, 30)
	ball.Anchored = true -- the script moves it, not physics
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false -- rays and blasts never find the fireball itself
	ball.CastShadow = false
	ball.Position = position

	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Parent = ball
	local light = Instance.new("PointLight")
	light.Color = ball.Color
	light.Range = 12
	light.Brightness = 2
	light.Parent = ball

	ball.Parent = workspace
	return ball
end

local function explode(caster: Player, casterCharacter: Model, position: Vector3)
	-- The explosion is only the look: no push, and it breaks no joints, so it kills no one by itself
	local blast = Instance.new("Explosion")
	blast.Position = position
	blast.BlastRadius = BLAST_RADIUS
	blast.BlastPressure = 0
	blast.DestroyJointRadiusPercent = 0
	blast.Parent = workspace

	local params = OverlapParams.new()
	params.ExcludeInstances = { casterCharacter } -- your own fireball never hurts you
	local alreadyHit: { [Model]: boolean } = {}
	for _, part in workspace:GetPartBoundsInRadius(position, BLAST_RADIUS, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if model and humanoid and humanoid.Health > 0 and not alreadyHit[model] then
			alreadyHit[model] = true -- one hit per character, however many of its parts are in range
			if not isTeammate(caster, Players:GetPlayerFromCharacter(model)) then
				humanoid:TakeDamage(DAMAGE)
			end
		end
	end
end

local function launch(caster: Player, casterCharacter: Model, root: BasePart, origin: Vector3, direction: Vector3)
	local rayParams = RaycastParams.new()
	rayParams.ExcludeInstances = { casterCharacter }

	-- If the spawn point is behind a wall (the player hugs it), explode on the wall straight away
	local blocked = workspace:Raycast(root.Position, origin - root.Position, rayParams)
	if blocked then
		explode(caster, casterCharacter, blocked.Position)
		return
	end

	local ball = makeBall(origin)
	local position = origin
	local travelled = 0
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local step = direction * SPEED * deltaTime
		-- Cast along this frame's step. Anything in the way is the hit.
		local result = workspace:Raycast(position, step, rayParams)
		if result then
			if connection then
				connection:Disconnect()
			end
			ball:Destroy()
			explode(caster, casterCharacter, result.Position)
			return
		end
		position += step
		travelled += step.Magnitude
		ball.Position = position
		if travelled >= MAX_RANGE then
			if connection then
				connection:Disconnect()
			end
			ball:Destroy()
		end
	end)
end

castEvent.OnServerEvent:Connect(function(player: Player, aimPoint: unknown)
	-- 1. The only argument is a position. Check its type and refuse NaN, which is never equal to itself.
	if typeof(aimPoint) ~= "Vector3" or aimPoint ~= aimPoint then
		return
	end

	-- 2. Alive, holding the Tool, off cooldown: all decided here
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if not (character and humanoid and root) or humanoid.Health <= 0 then
		return
	end
	if REQUIRE_TOOL then
		local tool = character:FindFirstChild(TOOL_NAME)
		if not (tool and tool:IsA("Tool")) then
			return
		end
	end
	local now = os.clock()
	if now - (lastCast[player] or 0) < COOLDOWN then
		return
	end

	-- 3. The fireball starts in front of the player's chest, not wherever the client says
	local origin = root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
	local offset = aimPoint - origin
	if offset.Magnitude < 1 or offset.Magnitude > 100000 then
		return -- too close to aim, or a huge or infinite position
	end
	lastCast[player] = now
	launch(player, character, root, origin, offset.Unit)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastCast[player] = nil
end)
