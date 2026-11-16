--!strict
-- How to make a settings menu in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-settings-menu
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named SettingsMenu
-- LocalScript in StarterPlayerScripts named SettingsMenu.
-- A gear button opens a panel of on/off switches. Each switch changes the game on
-- this device straight away, and the server saves it for next time.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local changeEvent = ReplicatedStorage:WaitForChild("ChangeSetting") :: RemoteEvent
local player = Players.LocalPlayer

-- The switches in the order they appear, with the text shown
local SETTINGS = {
	{ name = "Music", label = "Music" },
	{ name = "SoundEffects", label = "Sound effects" },
	{ name = "Shadows", label = "Shadows" },
}

-- What each setting does on this device. Changes made by a LocalScript stay on this device.
local function apply(name: string, on: boolean)
	if name == "Music" then
		local music = SoundService:FindFirstChild("Music")
		if music then
			for _, sound in music:GetChildren() do
				if sound:IsA("Sound") then
					sound.Volume = if on then 0.4 else 0
				end
			end
		end
	elseif name == "SoundEffects" then
		local effects = SoundService:FindFirstChild("Effects")
		if effects and effects:IsA("SoundGroup") then
			effects.Volume = if on then 0.5 else 0
		end
	elseif name == "Shadows" then
		Lighting.GlobalShadows = on
	end
end

local function get(name: string): boolean
	return player:GetAttribute("Setting_" .. name) ~= false
end

-- The gear button and the panel
local gui = Instance.new("ScreenGui")
gui.Name = "SettingsGui"
gui.ResetOnSpawn = false
local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end
local gear = Instance.new("TextButton")
gear.Text = "Settings"
gear.Size = UDim2.fromOffset(100, 40)
gear.Position = UDim2.new(0, 12, 0.5, -52)
gear.BackgroundColor3 = Color3.fromRGB(70, 64, 90)
gear.TextColor3 = Color3.new(1, 1, 1)
gear.Font = Enum.Font.GothamBold
gear.TextSize = 16
corner(gear, 10)
gear.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(340, 60 + #SETTINGS * 52)
panel.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
panel.Visible = false
corner(panel, 14)
panel.Parent = gui
local heading = Instance.new("TextLabel")
heading.Text = "Settings"
heading.Size = UDim2.new(1, 0, 0, 48)
heading.BackgroundTransparency = 1
heading.TextColor3 = Color3.new(1, 1, 1)
heading.Font = Enum.Font.GothamBold
heading.TextSize = 20
heading.Parent = panel

local switches: { [string]: TextButton } = {}
local function drawSwitch(name: string)
	local on = get(name)
	local switch = switches[name]
	switch.Text = if on then "ON" else "OFF"
	switch.BackgroundColor3 = if on then Color3.fromRGB(70, 200, 110) else Color3.fromRGB(90, 84, 104)
end

for i, setting in SETTINGS do
	local row = Instance.new("TextLabel")
	row.Text = setting.label
	row.Size = UDim2.new(1, -120, 0, 44)
	row.Position = UDim2.fromOffset(20, 48 + (i - 1) * 52)
	row.BackgroundTransparency = 1
	row.TextColor3 = Color3.new(1, 1, 1)
	row.Font = Enum.Font.Gotham
	row.TextSize = 17
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = panel
	local switch = Instance.new("TextButton")
	switch.Size = UDim2.fromOffset(80, 36)
	switch.Position = UDim2.new(1, -100, 0, 52 + (i - 1) * 52)
	switch.TextColor3 = Color3.new(1, 1, 1)
	switch.Font = Enum.Font.GothamBold
	switch.TextSize = 16
	corner(switch, 18)
	switch.Parent = panel
	switches[setting.name] = switch
	drawSwitch(setting.name)
	switch.Activated:Connect(function()
		local on = not get(setting.name)
		-- Change it here at once; the server checks it, stores it and saves it
		player:SetAttribute("Setting_" .. setting.name, on)
		changeEvent:FireServer(setting.name, on)
	end)
	-- Redraw and apply whenever the value changes, including when the server loads it
	player:GetAttributeChangedSignal("Setting_" .. setting.name):Connect(function()
		drawSwitch(setting.name)
		apply(setting.name, get(setting.name))
	end)
	apply(setting.name, get(setting.name))
end

gear.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
gui.Parent = player:WaitForChild("PlayerGui")
