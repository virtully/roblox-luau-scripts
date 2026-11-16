--!strict
-- How to make a round system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-round-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the RoundHud ScreenGui in StarterGui named RoundHudClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local screenGui = script.Parent :: ScreenGui

-- The label. If you designed your own TextLabel in RoundHud, delete this block and use:
-- local label = screenGui:WaitForChild("StatusLabel") :: TextLabel
local label = Instance.new("TextLabel")
label.Name = "StatusLabel"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(320, 44)
label.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.BuilderSansBold
label.TextSize = 22
label.TextWrapped = true -- longer messages use a second line
label.Text = ""
label.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function update()
	local status = roundInfo:GetAttribute("Status")
	local timeLeft = roundInfo:GetAttribute("TimeLeft")
	local text = if type(status) == "string" then status else ""
	if type(timeLeft) == "number" and timeLeft > 0 then
		text ..= "   " .. formatTime(timeLeft)
	end
	label.Text = text
end

roundInfo:GetAttributeChangedSignal("Status"):Connect(update)
roundInfo:GetAttributeChangedSignal("TimeLeft"):Connect(update)
update()
