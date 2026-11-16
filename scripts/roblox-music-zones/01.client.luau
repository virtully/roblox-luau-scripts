--!strict
-- How to make music zones in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-music-zones
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MusicZones
-- LocalScript in StarterPlayerScripts named MusicZones.
-- Plays the music of the zone the player stands in, with a cross-fade.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ZONE_TAG = "MusicZone"
local FADE_SECONDS = 1.5
local CHECK_EVERY = 0.5 -- seconds between zone checks
local DEFAULT_SOUND_ID = "" -- music outside every zone, or "" for silence
local DEFAULT_VOLUME = 0.5

local player = Players.LocalPlayer

-- one Sound per SoundId, made the first time it is needed
local sounds: { [string]: Sound } = {}
local currentId = ""

local function soundFor(soundId: string): Sound
	local existing = sounds[soundId]
	if existing then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sounds[soundId] = sound
	return sound
end

local function numberAttribute(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function isInside(zone: BasePart, position: Vector3): boolean
	local localPoint = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

-- the zone the position is in; the highest Priority wins where zones overlap
local function zoneAt(position: Vector3): BasePart?
	local best: BasePart? = nil
	local bestPriority = -math.huge
	for _, zone in CollectionService:GetTagged(ZONE_TAG) do
		if zone:IsA("BasePart") and isInside(zone, position) then
			local priority = numberAttribute(zone, "Priority", 0)
			if priority > bestPriority then
				best, bestPriority = zone, priority
			end
		end
	end
	return best
end

local function playTrack(soundId: string, volume: number)
	if soundId == currentId then
		return
	end
	local fade = TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	if currentId ~= "" then
		local old = soundFor(currentId)
		local fadeOut = TweenService:Create(old, fade, { Volume = 0 })
		fadeOut.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and old.SoundId ~= currentId then
				old:Pause() -- keep its place in case the player walks back
			end
		end)
		fadeOut:Play()
	end
	currentId = soundId
	if soundId ~= "" then
		local new = soundFor(soundId)
		if not new.IsPlaying then
			new:Resume()
		end
		TweenService:Create(new, fade, { Volume = volume }):Play()
	end
end

while true do
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local zone = zoneAt(root.Position)
		if zone then
			local id = zone:GetAttribute("SoundId")
			playTrack(if typeof(id) == "string" then id else "", numberAttribute(zone, "Volume", DEFAULT_VOLUME))
		else
			playTrack(DEFAULT_SOUND_ID, DEFAULT_VOLUME)
		end
	end
	task.wait(CHECK_EVERY)
end
