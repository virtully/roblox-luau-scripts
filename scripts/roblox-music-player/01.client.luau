--!strict
-- How to add a music player to your Roblox game
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-music-player
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MusicPlayer
-- LocalScript in StarterPlayerScripts named MusicPlayer.
-- Plays every Sound inside SoundService.Music in a shuffled loop, with a small
-- player in the corner: song name, Next and Mute. Each player controls their own music.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local VOLUME = 0.4 -- 0 to 1
local SHUFFLE = true

local folder = SoundService:WaitForChild("Music")
local songs: { Sound } = {}
for _, child in folder:GetChildren() do
	if child:IsA("Sound") then
		child.Looped = false
		table.insert(songs, child)
	end
end
if #songs == 0 then
	warn("MusicPlayer: put Sound objects inside SoundService.Music")
	return
end

-- The small player in the bottom-right corner
local gui = Instance.new("ScreenGui")
gui.Name = "MusicGui"
gui.ResetOnSpawn = false
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(1, 1)
frame.Position = UDim2.new(1, -12, 1, -12)
frame.Size = UDim2.fromOffset(260, 44)
frame.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
frame.BackgroundTransparency = 0.15
frame.Parent = gui
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -96, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.Gotham
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = frame

local function smallButton(text: string, x: number): TextButton
	local b = Instance.new("TextButton")
	b.Text = text
	b.Size = UDim2.fromOffset(38, 32)
	b.Position = UDim2.new(1, x, 0.5, -16)
	b.BackgroundColor3 = Color3.fromRGB(110, 80, 220)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	b.Parent = frame
	return b
end
local nextButton = smallButton(">>", -86)
local muteButton = smallButton("On", -44)
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local order: { number } = {}
local position = 0
local current: Sound? = nil
local muted = false

-- Off when this player pressed Mute, or turned Music off in a settings menu that sets the
-- Setting_Music attribute (see the settings menu guide)
local function volume(): number
	local settingOff = Players.LocalPlayer:GetAttribute("Setting_Music") == false
	return if muted or settingOff then 0 else VOLUME
end

local function shuffle()
	order = {}
	for i = 1, #songs do
		table.insert(order, i)
	end
	if SHUFFLE then
		for i = #order, 2, -1 do
			local j = math.random(i)
			order[i], order[j] = order[j], order[i]
		end
	end
	position = 0
end

local function playNext()
	if current then
		current:Stop()
	end
	position += 1
	if position > #order then
		shuffle()
		position = 1
	end
	local song = songs[order[position]]
	current = song
	song.Volume = volume()
	song:Play()
	title.Text = song.Name -- name each Sound after its song
end

for _, song in songs do
	song.Ended:Connect(function()
		if song == current then
			playNext()
		end
	end)
end

nextButton.Activated:Connect(playNext)
muteButton.Activated:Connect(function()
	muted = not muted
	muteButton.Text = if muted then "Off" else "On"
	if current then
		current.Volume = volume()
	end
end)

shuffle()
playNext()
