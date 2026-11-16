--!strict
-- How to use Cursor (or VS Code) with Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/cursor-roblox-studio
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named HealPads
--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

type Tracker = { ready: (player: Player) -> boolean, forget: (player: Player) -> () }
type CooldownModule = { new: (seconds: number) -> Tracker }

-- Cooldown.luau sits in the same folder as this file, so it is a sibling in Studio
local folder = script.Parent :: Instance
local Cooldown = require(folder:WaitForChild("Cooldown")) :: CooldownModule

local TAG = "HealPad"
local HEAL_AMOUNT = 25
local REACH = 10 -- studs of slack beyond the pad's size, for lag and the character's height
local healCooldown = Cooldown.new(3)

local function onTouched(pad: BasePart, hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not (character and player) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return
	end
	-- An exploiter can fire Touched from any distance, so check the character is at the pad
	local root = humanoid.RootPart
	if not root or (root.Position - pad.Position).Magnitude > pad.Size.Magnitude / 2 + REACH then
		return
	end
	if not healCooldown.ready(player) then
		return -- Touched fires many times a second; heal at most once per cooldown
	end
	humanoid.Health = math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
end

local connections: { [Instance]: RBXScriptConnection } = {}

local function addPad(instance: Instance)
	if not instance:IsA("BasePart") or connections[instance] then
		return
	end
	local pad = instance :: BasePart
	connections[pad] = pad.Touched:Connect(function(hit: BasePart)
		onTouched(pad, hit)
	end)
end

local function removePad(pad: Instance)
	local connection = connections[pad]
	if connection then
		connection:Disconnect()
		connections[pad] = nil
	end
end

for _, pad in CollectionService:GetTagged(TAG) do
	addPad(pad)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(addPad)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(removePad)

Players.PlayerRemoving:Connect(function(player: Player)
	healCooldown.forget(player)
end)
