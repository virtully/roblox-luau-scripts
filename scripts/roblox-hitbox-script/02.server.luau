--!strict
-- How to make a melee hitbox in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-hitbox-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named MeleeHitbox
-- Script in ServerScriptService named MeleeHitbox.
-- Every Tool tagged "Melee" checks a box in front of its holder after each click.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DAMAGE = 20 -- health each hit takes
local SWING_COOLDOWN = 0.6 -- seconds between swings for one player
local HITBOX_SIZE = Vector3.new(5, 5, 5) -- width, height and depth of the box in studs
local HITBOX_DISTANCE = 3.5 -- studs from the attacker's root to the centre of the box
local WINDUP = 0.1 -- seconds between the click and the hitbox turning on
local ACTIVE_TIME = 0.2 -- seconds the hitbox stays on
local FRIENDLY_FIRE = false -- true lets players hurt their own team
local SHOW_HITBOX = false -- true draws the box in red while it is on

local lastSwing: { [Player]: number } = {}

local function isTeammate(attacker: Player, target: Player?): boolean
	if FRIENDLY_FIRE or not target then
		return false
	end
	return not attacker.Neutral and not target.Neutral and attacker.Team == target.Team
end

-- A red see-through part that shows where the hitbox is. CanQuery is off,
-- so the hitbox never finds its own debug part.
local function makeDebugBox(): Part
	local box = Instance.new("Part")
	box.Name = "HitboxDebug"
	box.Anchored = true
	box.CanCollide = false
	box.CanTouch = false
	box.CanQuery = false
	box.Transparency = 0.7
	box.Color = Color3.fromRGB(255, 60, 60)
	box.Size = HITBOX_SIZE
	box.Parent = workspace
	return box
end

local function swing(attacker: Player, character: Model, root: BasePart)
	local params = OverlapParams.new()
	params.ExcludeInstances = { character } -- never hit yourself or your own sword
	local alreadyHit: { [Model]: boolean } = {} -- one hit per character per swing
	local debugBox = if SHOW_HITBOX then makeDebugBox() else nil
	local startTime = os.clock()

	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function()
		-- Turn the hitbox off when its time is up or the attacker is gone
		if os.clock() - startTime > ACTIVE_TIME or not root:IsDescendantOf(workspace) then
			if connection then
				connection:Disconnect()
			end
			if debugBox then
				debugBox:Destroy()
			end
			return
		end

		-- The box follows the attacker: HITBOX_DISTANCE studs in front of their root
		local boxCFrame = root.CFrame * CFrame.new(0, 0, -HITBOX_DISTANCE)
		if debugBox then
			debugBox.CFrame = boxCFrame
		end

		for _, part in workspace:GetPartBoundsInBox(boxCFrame, HITBOX_SIZE, params) do
			local model = part:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if model and humanoid and humanoid.Health > 0 and not alreadyHit[model] then
				alreadyHit[model] = true
				if not isTeammate(attacker, Players:GetPlayerFromCharacter(model)) then
					humanoid:TakeDamage(DAMAGE)
				end
			end
		end
	end)
end

local function setUpTool(instance: Instance)
	if not instance:IsA("Tool") then
		return
	end
	local tool = instance
	-- Activated fires on the server too, so the client needs no RemoteEvent for a click
	tool.Activated:Connect(function()
		local character = tool.Parent
		if not (character and character:IsA("Model")) then
			return
		end
		local attacker = Players:GetPlayerFromCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if not (attacker and humanoid and root) or humanoid.Health <= 0 then
			return
		end

		-- The cooldown is checked here, on the server, per player
		local now = os.clock()
		if now - (lastSwing[attacker] or 0) < SWING_COOLDOWN then
			return
		end
		lastSwing[attacker] = now

		task.wait(WINDUP)
		-- Still holding this weapon and still alive after the windup?
		if tool.Parent ~= character or humanoid.Health <= 0 then
			return
		end
		swing(attacker, character, root)
	end)
end

for _, tool in CollectionService:GetTagged("Melee") do
	setUpTool(tool)
end
CollectionService:GetInstanceAddedSignal("Melee"):Connect(setUpTool)

Players.PlayerRemoving:Connect(function(player: Player)
	lastSwing[player] = nil
end)
