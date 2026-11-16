--!strict
-- How to make rain and a weather system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-rain-weather
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named WeatherService
-- Script in ServerScriptService named WeatherService.
-- Picks the weather and tells every client through attributes on the Workspace.
type Weather = { name: string, weight: number, minSeconds: number, maxSeconds: number }

-- weight: how often it is picked compared with the others
local WEATHERS: { Weather } = {
	{ name = "Clear", weight = 5, minSeconds = 180, maxSeconds = 300 },
	{ name = "Rain", weight = 3, minSeconds = 90, maxSeconds = 180 },
	{ name = "Storm", weight = 1, minSeconds = 60, maxSeconds = 120 },
}
local THUNDER_MIN_GAP = 6 -- seconds between lightning strikes in a storm
local THUNDER_MAX_GAP = 20

local function pickNext(current: string?): Weather
	-- Weighted random choice, never the same weather twice in a row
	local total = 0
	for _, weather in WEATHERS do
		if weather.name ~= current then
			total += weather.weight
		end
	end
	local roll = math.random() * total
	for _, weather in WEATHERS do
		if weather.name ~= current then
			roll -= weather.weight
			if roll <= 0 then
				return weather
			end
		end
	end
	return WEATHERS[1]
end

local current: string? = nil
workspace:SetAttribute("Weather", "Clear")

while true do
	local weather = pickNext(current)
	current = weather.name
	workspace:SetAttribute("Weather", weather.name)
	local duration = math.random(weather.minSeconds, weather.maxSeconds)
	local endTime = os.clock() + duration

	if weather.name == "Storm" then
		-- Lightning: a new time stamp in ThunderAt is each client's cue to flash and rumble
		while os.clock() < endTime do
			task.wait(math.random(THUNDER_MIN_GAP, THUNDER_MAX_GAP))
			if os.clock() < endTime and workspace:GetAttribute("Weather") == "Storm" then
				workspace:SetAttribute("ThunderAt", workspace:GetServerTimeNow())
			end
		end
	else
		task.wait(duration)
	end
end
