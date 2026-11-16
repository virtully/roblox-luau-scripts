--!strict
-- How to make a combat system with hitboxes in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-combat-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CombatService
-- Script in ServerScriptService named CombatService.
-- Punch combos: the client asks to punch, the server checks the cooldown, finds
-- targets in a box in front of the attacker and deals the damage.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DAMAGE = 10 -- per punch
local FINISHER_DAMAGE = 20 -- the last punch of a combo
local COMBO_LENGTH = 3
local PUNCH_COOLDOWN = 0.35 -- seconds between punches
local COMBO_RESET = 1 -- seconds without a punch before the combo starts over
local HITBOX_SIZE = Vector3.new(5, 5, 5)
local HITBOX_DISTANCE = 3.5 -- studs in front of the attacker's root

local punchEvent = Instance.new("RemoteEvent")
punchEvent.Name = "Punch"
punchEvent.Parent = ReplicatedStorage

type State = { last: number, combo: number }
local states: { [Player]: State } = {}

local function addKO(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local kos = leaderstats and leaderstats:FindFirstChild("KOs")
	if kos and kos:IsA("IntValue") then
		kos.Value += 1
	end
end

punchEvent.OnServerEvent:Connect(function(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if not (character and humanoid and root) or humanoid.Health <= 0 then
		return
	end

	-- The server keeps its own clock, so a cheater cannot punch faster by firing more often
	local now = os.clock()
	local state: State = states[player] or { last = -math.huge, combo = 0 }
	states[player] = state
	if now - state.last < PUNCH_COOLDOWN then
		return
	end
	state.combo = if now - state.last > COMBO_RESET then 1 else state.combo % COMBO_LENGTH + 1
	state.last = now
	local damage = if state.combo == COMBO_LENGTH then FINISHER_DAMAGE else DAMAGE

	-- The hitbox: a box in front of where the server sees the attacker
	local boxCFrame = root.CFrame * CFrame.new(0, 0, -HITBOX_DISTANCE)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local hitHumanoids: { [Humanoid]: boolean } = {}
	for _, part in workspace:GetPartBoundsInBox(boxCFrame, HITBOX_SIZE, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		local targetPlayer = if model then Players:GetPlayerFromCharacter(model) else nil
		-- No friendly fire: skip players on the attacker's team
		local sameTeam = targetPlayer and not player.Neutral and targetPlayer.Team == player.Team
		-- One hit per Humanoid, however many of its parts are in the box
		if target and target.Health > 0 and not sameTeam and not hitHumanoids[target] then
			hitHumanoids[target] = true
			target:TakeDamage(damage)
			if target.Health <= 0 then
				addKO(player)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local kos = Instance.new("IntValue")
	kos.Name = "KOs"
	kos.Parent = leaderstats
	leaderstats.Parent = player
end)

Players.PlayerRemoving:Connect(function(player: Player)
	states[player] = nil
end)
