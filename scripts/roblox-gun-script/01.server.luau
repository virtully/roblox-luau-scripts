--!strict
-- How to make a gun in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gun-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GunService
-- Script in ServerScriptService named GunService.
-- The client only says where the player is aiming. The server checks the shot,
-- casts its own ray from the gun, deals the damage and tells everyone to draw it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings
local GUN_NAME = "Blaster" -- the Tool's name in StarterPack
local DAMAGE = 25
local HEADSHOT_MULTIPLIER = 2
local FIRE_INTERVAL = 0.25 -- seconds between shots; keep the same value in GunClient
local MAX_RANGE = 300 -- studs
local MAGAZINE_SIZE = 12
local RELOAD_SECONDS = 1.5
local FRIENDLY_FIRE = false
-- Shots sent exactly FIRE_INTERVAL apart can arrive a little closer together after a
-- network delay, so the server allows this much slack instead of dropping a real shot
local NETWORK_SLACK = 0.05

local function newRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local fireEvent = newRemote("GunFire") -- client to server: the aim point
local reloadEvent = newRemote("GunReload") -- client to server: please reload
local shotEvent = newRemote("GunShot") -- server to every client: draw this shot

local lastShot: { [Player]: number } = {}
local reloading: { [Tool]: boolean } = {}

-- Returns the gun the player is holding, but only while they are alive
local function getHeldGun(player: Player): (Tool?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and humanoid) or humanoid.Health <= 0 then
		return nil, nil
	end
	local gun = character:FindFirstChild(GUN_NAME)
	local handle = gun and gun:FindFirstChild("Handle")
	if gun and gun:IsA("Tool") and handle and handle:IsA("BasePart") then
		return gun, handle
	end
	return nil, nil
end

local function reload(gun: Tool)
	local ammo = gun:GetAttribute("Ammo")
	if reloading[gun] or ammo == nil or ammo == MAGAZINE_SIZE then -- nil: never fired, so already full
		return
	end
	reloading[gun] = true
	gun:SetAttribute("Reloading", true)
	task.wait(RELOAD_SECONDS)
	reloading[gun] = nil
	if gun.Parent then
		gun:SetAttribute("Ammo", MAGAZINE_SIZE)
		gun:SetAttribute("Reloading", false)
	end
end

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

local function onFire(player: Player, aimPoint: unknown)
	-- 1. The only argument is a position. Check its type, and refuse NaN, which is never equal to itself.
	if typeof(aimPoint) ~= "Vector3" or aimPoint ~= aimPoint then
		return
	end

	-- 2. Fire rate, held gun and ammo are all decided here, not on the client
	local now = os.clock()
	local last = lastShot[player]
	if last and now - last < FIRE_INTERVAL - NETWORK_SLACK then
		return
	end
	local gun, handle = getHeldGun(player)
	if not (gun and handle) or reloading[gun] then
		return
	end
	local stored = gun:GetAttribute("Ammo")
	local ammo: number = if type(stored) == "number" then stored else MAGAZINE_SIZE -- no attribute yet: a full magazine
	if ammo <= 0 then
		task.spawn(reload, gun)
		return
	end

	-- 3. The server casts its own ray: from the gun, towards the aim point, at most MAX_RANGE long
	local origin = handle.Position
	local offset = aimPoint - origin
	if offset.Magnitude < 0.5 or offset.Magnitude > 100000 then
		return -- also refuses an infinite position, which would break the ray
	end
	local params = RaycastParams.new()
	params.ExcludeInstances = { player.Character :: Model } -- skip the shooter's own body and blaster
	-- A blaster poking through a thin wall must not fire from the far side of it
	local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and workspace:Raycast(root.Position, origin - root.Position, params) then
		return
	end
	lastShot[player] = now -- only a shot that is really fired uses the fire rate and a round
	gun:SetAttribute("Ammo", ammo - 1)
	local direction = offset.Unit * MAX_RANGE
	local result = workspace:Raycast(origin, direction, params)

	-- 4. Damage whatever Humanoid the ray hit
	local hitPosition = origin + direction
	if result then
		hitPosition = result.Position
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		if model and target and target.Health > 0 and not isTeammate(player, Players:GetPlayerFromCharacter(model)) then
			local damage = if result.Instance.Name == "Head" then DAMAGE * HEADSHOT_MULTIPLIER else DAMAGE
			target:TakeDamage(damage)
		end
	end

	-- 5. Every client draws the shot, from the gun to where the server's ray ended
	shotEvent:FireAllClients(handle, hitPosition)
end

fireEvent.OnServerEvent:Connect(onFire)

reloadEvent.OnServerEvent:Connect(function(player: Player)
	local gun = getHeldGun(player)
	if gun then
		reload(gun)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastShot[player] = nil
end)
