--!strict
-- How to make rain and a weather system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-rain-weather
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named WeatherClient
-- LocalScript in StarterPlayerScripts named WeatherClient.
-- Draws the weather the server picked: rain, fog, light, sound and thunder.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local RAIN_RATE = 500 -- raindrops per second in Rain; Storm doubles it
local RAIN_HEIGHT = 40 -- studs above the camera where drops start
local RAIN_AREA = 90 -- width of the rain box around the camera, in studs
local FADE_SECONDS = 6 -- how long fog and light take to change
local RAIN_SOUND_ID = "" -- a looping rain sound, for example "rbxassetid://123456"
local THUNDER_SOUND_ID = "" -- a thunder clap
local RAIN_TEXTURE = "" -- a raindrop image; empty keeps the default particle

local player = Players.LocalPlayer

-- The Atmosphere gives fog and haze. Use the place's own, or add one.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
	local created = Instance.new("Atmosphere")
	created.Parent = Lighting
	atmosphere = created
end
local fog = atmosphere :: Atmosphere

-- Clear weather is whatever the place already looks like
type Look = { density: number, haze: number, color: Color3, brightness: number }
local clear: Look = { density = fog.Density, haze = fog.Haze, color = fog.Color, brightness = Lighting.Brightness }
local LOOKS: { [string]: Look } = {
	Clear = clear,
	Rain = { density = 0.45, haze = 2, color = Color3.fromRGB(150, 156, 168), brightness = clear.brightness * 0.6 },
	Storm = { density = 0.55, haze = 3, color = Color3.fromRGB(105, 110, 122), brightness = clear.brightness * 0.35 },
}

-- An invisible box above the camera that rain falls out of. Only this client has it.
local rainBox = Instance.new("Part")
rainBox.Name = "RainBox"
rainBox.Anchored = true
rainBox.CanCollide = false
rainBox.CanTouch = false
rainBox.CanQuery = false
rainBox.Transparency = 1
rainBox.Size = Vector3.new(RAIN_AREA, 1, RAIN_AREA)
rainBox.Parent = workspace

local emitter = Instance.new("ParticleEmitter")
emitter.Shape = Enum.ParticleEmitterShape.Box
emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume -- drops start anywhere inside the box
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Speed = NumberRange.new(70, 85)
emitter.Lifetime = NumberRange.new(0.8, 1)
emitter.Orientation = Enum.ParticleOrientation.VelocityParallel -- stretch along the fall
emitter.Squash = NumberSequence.new(2) -- above 0: thinner and taller, a streak
emitter.Size = NumberSequence.new(0.15)
emitter.Transparency = NumberSequence.new(0.4)
emitter.Color = ColorSequence.new(Color3.fromRGB(200, 210, 225))
emitter.LightInfluence = 1
emitter.Rate = 0
if RAIN_TEXTURE ~= "" then
	emitter.Texture = RAIN_TEXTURE
end
emitter.Parent = rainBox

local rainSound = Instance.new("Sound")
rainSound.Name = "RainLoop"
rainSound.Looped = true
rainSound.Volume = 0
rainSound.SoundId = RAIN_SOUND_ID
rainSound.Parent = SoundService

local currentRate = 0 -- the rate for this weather, before the roof check
local indoors = false

local fadeInfo = TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Sine)

local function applyWeather()
	local name = workspace:GetAttribute("Weather")
	local look = if type(name) == "string" and LOOKS[name] then LOOKS[name] else clear
	TweenService:Create(fog, fadeInfo, { Density = look.density, Haze = look.haze, Color = look.color }):Play()
	TweenService:Create(Lighting, fadeInfo, { Brightness = look.brightness }):Play()

	currentRate = if name == "Storm" then RAIN_RATE * 2 elseif name == "Rain" then RAIN_RATE else 0
	local volume = if name == "Storm" then 0.8 elseif name == "Rain" then 0.5 else 0
	if volume > 0 and RAIN_SOUND_ID ~= "" and not rainSound.IsPlaying then
		rainSound:Play()
	end
	TweenService:Create(rainSound, fadeInfo, { Volume = volume }):Play()
end

-- Thunder: a quick flash, then the rumble a moment later (sound travels slower than light)
local function onThunder()
	if workspace:GetAttribute("Weather") ~= "Storm" then
		return
	end
	local flashUp = TweenService:Create(Lighting, TweenInfo.new(0.08), { ExposureCompensation = 1.5 })
	local flashDown = TweenService:Create(Lighting, TweenInfo.new(0.5), { ExposureCompensation = 0 })
	flashUp:Play()
	flashUp.Completed:Once(function()
		flashDown:Play()
	end)
	if THUNDER_SOUND_ID ~= "" then
		task.delay(0.4 + math.random() * 1.2, function()
			local thunder = Instance.new("Sound")
			thunder.SoundId = THUNDER_SOUND_ID
			thunder.Volume = 0.8
			thunder.Parent = SoundService
			thunder:Play()
			thunder.Ended:Once(function()
				thunder:Destroy()
			end)
		end)
	end
end

workspace:GetAttributeChangedSignal("Weather"):Connect(applyWeather)
workspace:GetAttributeChangedSignal("ThunderAt"):Connect(onThunder)
applyWeather()

-- Every frame: keep the rain box above the camera. A few times a second: check for a roof.
local roofParams = RaycastParams.new()
local sinceRoofCheck = 0
RunService.RenderStepped:Connect(function(deltaTime: number)
	local camera = workspace.CurrentCamera
	local position = camera.CFrame.Position
	rainBox.CFrame = CFrame.new(position + Vector3.new(0, RAIN_HEIGHT, 0))

	sinceRoofCheck += deltaTime
	if sinceRoofCheck >= 0.2 then
		sinceRoofCheck = 0
		local character = player.Character
		roofParams.ExcludeInstances = if character then { character } else {}
		-- Anything solid above the camera counts as a roof
		indoors = workspace:Raycast(position, Vector3.new(0, RAIN_HEIGHT + 60, 0), roofParams) ~= nil
	end

	emitter.Rate = if indoors then 0 else currentRate
	-- Rain sounds muffled indoors instead of stopping
	rainSound.PlaybackSpeed = if indoors then 0.85 else 1
end)
