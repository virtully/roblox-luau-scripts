--!strict
-- How to make a day and night cycle in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-day-night-cycle
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named StreetLights
-- Script in ServerScriptService named StreetLights.
-- Turns on every light inside parts tagged "StreetLight" at night, and off by day.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local LIGHTS_ON_HOUR = 18 -- 6 pm
local LIGHTS_OFF_HOUR = 6.5 -- 6:30 am

local function isNight(): boolean
	local hour = Lighting.ClockTime
	return hour >= LIGHTS_ON_HOUR or hour < LIGHTS_OFF_HOUR
end

local function setLamp(lamp: Instance, on: boolean)
	for _, child in lamp:GetDescendants() do
		if child:IsA("Light") then
			child.Enabled = on
		end
	end
	if lamp:IsA("BasePart") then
		lamp.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local lightsOn: boolean? = nil
local function update()
	local night = isNight()
	if night == lightsOn then
		return -- nothing changed since the last check
	end
	lightsOn = night
	for _, lamp in CollectionService:GetTagged("StreetLight") do
		setLamp(lamp, night)
	end
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
CollectionService:GetInstanceAddedSignal("StreetLight"):Connect(function(lamp: Instance)
	setLamp(lamp, isNight())
end)
update()
