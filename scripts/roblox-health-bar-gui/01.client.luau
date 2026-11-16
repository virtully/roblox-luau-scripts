--!strict
-- How to make a custom health bar in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-health-bar-gui
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named HealthBar
-- LocalScript in StarterPlayerScripts named HealthBar.
-- Replaces Roblox's health bar with a bigger one that shows numbers, slides when
-- health changes and turns from green to red.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local FULL_COLOR = Color3.fromRGB(70, 220, 110)
local EMPTY_COLOR = Color3.fromRGB(235, 60, 60)
local HIDE_DEFAULT = true -- hide Roblox's own health bar

local player = Players.LocalPlayer

if HIDE_DEFAULT then
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

local gui = Instance.new("ScreenGui")
gui.Name = "HealthGui"
gui.ResetOnSpawn = false
local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -56)
back.Size = UDim2.fromOffset(300, 26)
back.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
back.Parent = gui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = FULL_COLOR
fill.BorderSizePixel = 0
fill.Parent = back
for _, frame in { back, fill } do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
end
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.5
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.ZIndex = 2
label.Parent = back
gui.Parent = player:WaitForChild("PlayerGui")

local slide = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function show(humanoid: Humanoid)
	local max = math.max(humanoid.MaxHealth, 1)
	local fraction = math.clamp(humanoid.Health / max, 0, 1)
	TweenService:Create(fill, slide, {
		Size = UDim2.fromScale(fraction, 1),
		BackgroundColor3 = EMPTY_COLOR:Lerp(FULL_COLOR, fraction),
	}):Play()
	label.Text = string.format("%d / %d", math.ceil(humanoid.Health), math.ceil(max))
end

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	show(humanoid)
	humanoid.HealthChanged:Connect(function()
		show(humanoid)
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		show(humanoid)
	end)
end

if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)
