--!strict
-- How to make a morph in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-morph-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Morphs
-- Script in ServerScriptService named Morphs.
-- Turns players into models from ServerStorage.Morphs, from MorphPad parts or a GUI button.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MORPH_COOLDOWN = 2 -- seconds between morphs for one player
local KEEP_AFTER_DEATH = false -- respawn as the last morph instead of the player's avatar

local morphFolder = ServerStorage:WaitForChild("Morphs")

local requestMorph = Instance.new("RemoteEvent")
requestMorph.Name = "RequestMorph"
requestMorph.Parent = ReplicatedStorage

local lastMorph: { [Player]: number } = {}
local morphing: { [Player]: boolean } = {}
local madeMorph: { [Player]: Model } = {} -- the last morph model this script gave each player

local function getMorphModel(name: string): Model?
	local model = morphFolder:FindFirstChild(name)
	if model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
		return model
	end
	return nil
end

local function morph(player: Player, name: string)
	local now = os.clock()
	if morphing[player] or now - (lastMorph[player] or -math.huge) < MORPH_COOLDOWN then
		return
	end
	local old = player.Character
	local oldHumanoid = old and old:FindFirstChildOfClass("Humanoid")
	if not (old and oldHumanoid) or oldHumanoid.Health <= 0 then
		return
	end
	lastMorph[player] = now

	if name == "" then
		-- An empty name changes the player back to their own avatar
		player:SetAttribute("Morph", nil)
		morphing[player] = true
		local pivot = old:GetPivot()
		player:LoadCharacterAsync()
		local character = player.Character
		if character then
			character:PivotTo(pivot) -- stay where you were instead of going to spawn
		end
		morphing[player] = nil
		return
	end

	local template = getMorphModel(name)
	if not template then
		return -- not a morph we offer
	end
	local new = template:Clone()
	new.Name = player.Name
	local humanoid = new:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = new:FindFirstChild("HumanoidRootPart") :: BasePart
	new.PrimaryPart = root

	-- A model with no Neck joint would die at once, because RequiresNeck is on by default
	local neck = new:FindFirstChild("Neck", true)
	if not (neck and neck:IsA("Motor6D")) then
		humanoid.RequiresNeck = false
	end

	-- Bring the old character's animation script if the morph has none and uses the same rig
	local animate = old:FindFirstChild("Animate")
	if animate and not new:FindFirstChild("Animate") and humanoid.RigType == oldHumanoid.RigType then
		animate:Clone().Parent = new
	end

	-- Same place and facing as the old character, lifted a little so it does not spawn in the floor
	new:PivotTo(old:GetPivot() + Vector3.new(0, 1, 0))
	player:SetAttribute("Morph", name)
	madeMorph[player] = new
	player.Character = new
	new.Parent = workspace
	old:Destroy()
end

-- Pads: any part tagged MorphPad, with a Morph attribute naming the model
local function setUpPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	pad.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
		if not player then
			return
		end
		local name = pad:GetAttribute("Morph")
		local wanted = if typeof(name) == "string" then name else ""
		if player:GetAttribute("Morph") == wanted or (wanted == "" and player:GetAttribute("Morph") == nil) then
			return -- already this morph
		end
		morph(player, wanted)
	end)
end

for _, pad in CollectionService:GetTagged("MorphPad") do
	setUpPad(pad)
end
CollectionService:GetInstanceAddedSignal("MorphPad"):Connect(setUpPad)

-- Buttons: the client sends only a name, checked here against the Morphs folder
requestMorph.OnServerEvent:Connect(function(player: Player, name: unknown)
	if typeof(name) ~= "string" or #name > 50 then
		return
	end
	if name ~= "" and not getMorphModel(name) then
		return
	end
	morph(player, name)
end)

-- A real respawn: come back as the same morph (optional), or clear the saved morph
local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		if character == madeMorph[player] then
			return -- this is the morph we just made, not a respawn
		end
		local name = player:GetAttribute("Morph")
		if KEEP_AFTER_DEATH and typeof(name) == "string" then
			task.defer(function()
				lastMorph[player] = nil -- no cooldown for this one
				morph(player, name)
			end)
		else
			player:SetAttribute("Morph", nil)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastMorph[player] = nil
	morphing[player] = nil
	madeMorph[player] = nil
end)
