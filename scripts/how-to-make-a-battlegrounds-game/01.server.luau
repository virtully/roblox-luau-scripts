--!strict
-- How to make a battlegrounds game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-battlegrounds-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Moves
-- Script in ServerScriptService named Moves.
-- The client asks for a move by name. The server checks cooldown and stun,
-- finds who is in the hitbox, then deals damage, stun and knockback.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Move = { cooldown: number, damage: number, reach: number, size: Vector3, push: number, lift: number, stun: number }
local MOVES: { [string]: Move } = {
	Uppercut = { cooldown = 6, damage = 12, reach = 4, size = Vector3.new(5, 6, 5), push = 10, lift = 45, stun = 0.8 },
	Slam = { cooldown = 12, damage = 18, reach = 0, size = Vector3.new(16, 6, 16), push = 50, lift = 15, stun = 1.2 },
	Shove = { cooldown = 4, damage = 5, reach = 5, size = Vector3.new(6, 6, 7), push = 70, lift = 5, stun = 0.3 },
}
local BLOCKED_DAMAGE = 0.2 -- share of damage that gets through a block, with no stun or push

local useMove = Instance.new("RemoteEvent")
useMove.Name = "UseMove"
useMove.Parent = ReplicatedStorage
local readyAt: { [Player]: { [string]: number } } = {}

local function isStunned(character: Model): boolean
	local untilTime = character:GetAttribute("StunnedUntil")
	return typeof(untilTime) == "number" and untilTime > workspace:GetServerTimeNow()
end

useMove.OnServerEvent:Connect(function(player, moveName)
	local move = if typeof(moveName) == "string" then MOVES[moveName] else nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (move and character and root and root:IsA("BasePart") and humanoid) then
		return
	end
	local mine = readyAt[player] or {}
	readyAt[player] = mine
	if humanoid.Health <= 0 or isStunned(character) or os.clock() < (mine[moveName] or 0) then
		return -- stunned, dead or on cooldown: ignore the request
	end
	mine[moveName] = os.clock() + move.cooldown

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local boxCenter = root.CFrame * CFrame.new(0, 0, -move.reach)
	local done: { [Model]: boolean } = {}
	for _, part in workspace:GetPartBoundsInBox(boxCenter, move.size, params) do
		local target = part:FindFirstAncestorOfClass("Model")
		local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
		local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
		if target and not done[target] and targetHumanoid and targetHumanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
			done[target] = true -- one hit per target, however many of its parts overlap
			if target:GetAttribute("Blocking") == true then
				targetHumanoid:TakeDamage(move.damage * BLOCKED_DAMAGE)
				continue
			end
			targetHumanoid:TakeDamage(move.damage)
			target:SetAttribute("StunnedUntil", workspace:GetServerTimeNow() + move.stun)
			local away = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
			local direction = if away.Magnitude > 0.1 then away.Unit else root.CFrame.LookVector
			local velocity = direction * move.push + Vector3.new(0, move.lift, 0)
			targetRoot:ApplyImpulse(velocity * targetRoot.AssemblyMass)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	readyAt[player] = nil
end)
