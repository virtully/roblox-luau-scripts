--!strict
-- How to make a simulator game on Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-simulator-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named SimulatorClient
-- Builds the simulator buttons and shows the server's numbers. It never changes them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

type Config = {
	MAX_POWER_LEVEL: number,
	clickValue: (powerLevel: number, rebirths: number) -> number,
	upgradeCost: (powerLevel: number) -> number,
	rebirthCost: (rebirths: number) -> number,
}
local Config = require(ReplicatedStorage:WaitForChild("SimulatorConfig")) :: Config
local remotes = ReplicatedStorage:WaitForChild("SimulatorRemotes")
local clickEvent = remotes:WaitForChild("Click") :: RemoteEvent
local buyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
local rebirthRemote = remotes:WaitForChild("Rebirth") :: RemoteFunction

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue
local rebirths = leaderstats:WaitForChild("Rebirths") :: IntValue

local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)

-- 1234 -> "1.2K", 5600000 -> "5.6M"
local UNITS = {
	{ size = 1e12, suffix = "T" },
	{ size = 1e9, suffix = "B" },
	{ size = 1e6, suffix = "M" },
	{ size = 1e3, suffix = "K" },
}
local function short(n: number): string
	for _, unit in UNITS do
		if n >= unit.size then
			return string.format("%.1f%s", math.floor(n / unit.size * 10) / 10, unit.suffix)
		end
	end
	return tostring(n)
end

local function newButton(parent: Instance, text: string, position: UDim2, size: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.FontFace = BOLD
	button.TextScaled = true
	button.Text = text
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "SimulatorGui"
gui.ResetOnSpawn = false

local coinsLabel = Instance.new("TextLabel")
coinsLabel.AnchorPoint = Vector2.new(0.5, 0)
coinsLabel.Position = UDim2.new(0.5, 0, 0, 12)
coinsLabel.Size = UDim2.fromOffset(320, 48)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 214, 90)
coinsLabel.FontFace = BOLD
coinsLabel.TextScaled = true
coinsLabel.Parent = gui

local clickButton = newButton(gui, "Click!", UDim2.new(0.5, 0, 0.5, -30), UDim2.fromScale(0.38, 0.38), Color3.fromRGB(124, 77, 255))
-- Keep the Click button square, sized to the screen and never bigger than 200 by 200,
-- so on a phone it fits between the coin count and the buttons at the bottom
local square = Instance.new("UIAspectRatioConstraint")
square.Parent = clickButton
local maxSize = Instance.new("UISizeConstraint")
maxSize.MaxSize = Vector2.new(200, 200)
maxSize.Parent = clickButton

local upgradeButton = newButton(gui, "", UDim2.new(0.5, -110, 1, -60), UDim2.fromOffset(200, 56), Color3.fromRGB(40, 150, 90))
local rebirthButton = newButton(gui, "", UDim2.new(0.5, 110, 1, -60), UDim2.fromOffset(200, 56), Color3.fromRGB(200, 90, 40))

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -96)
status.Size = UDim2.fromOffset(480, 28)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.FontFace = BOLD
status.TextSize = 20
status.Text = ""
status.Parent = gui

gui.Parent = player:WaitForChild("PlayerGui")

local function powerLevel(): number
	local level = player:GetAttribute("PowerLevel")
	return if type(level) == "number" then level else 1
end

local function update()
	coinsLabel.Text = `{short(coins.Value)} coins`
	local level = powerLevel()
	upgradeButton.Text = if level >= Config.MAX_POWER_LEVEL
		then "Click Power maxed"
		else `Upgrade: {short(Config.upgradeCost(level))}`
	rebirthButton.Text = `Rebirth: {short(Config.rebirthCost(rebirths.Value))}`
end
coins.Changed:Connect(update)
rebirths.Changed:Connect(update)
player:GetAttributeChangedSignal("PowerLevel"):Connect(update)
update()

-- A "+N" that floats up from the button. The number is a guess for show only;
-- the server decides what the click is really worth.
local function popUp()
	local pop = Instance.new("TextLabel")
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.1, 0.42)
	pop.Size = UDim2.fromOffset(120, 40)
	pop.BackgroundTransparency = 1
	pop.TextColor3 = Color3.fromRGB(255, 214, 90)
	pop.FontFace = BOLD
	pop.TextScaled = true
	pop.Text = `+{short(Config.clickValue(powerLevel(), rebirths.Value))}`
	pop.Parent = gui
	local tween = TweenService:Create(pop, TweenInfo.new(0.6), {
		Position = pop.Position - UDim2.fromOffset(0, 60),
		TextTransparency = 1,
	})
	tween.Completed:Once(function()
		pop:Destroy()
	end)
	tween:Play()
end

clickButton.Activated:Connect(function()
	clickEvent:FireServer()
	popUp()
end)

local function ask(remote: RemoteFunction)
	local ok, success, message = pcall(function()
		return remote:InvokeServer()
	end)
	status.Text = if ok and type(message) == "string" then message else "No answer from the server. Try again."
	status.TextColor3 = if ok and success == true then Color3.fromRGB(120, 220, 150) else Color3.new(1, 1, 1)
end

upgradeButton.Activated:Connect(function()
	ask(buyUpgrade)
end)
rebirthButton.Activated:Connect(function()
	ask(rebirthRemote)
end)
