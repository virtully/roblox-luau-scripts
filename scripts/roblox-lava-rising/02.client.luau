--!strict
-- How to make a rising lava game in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-lava-rising
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the RoundStatus ScreenGui named RoundStatusLabel
-- LocalScript inside a ScreenGui named RoundStatus in StarterGui.
-- Shows the round status the LavaRounds Script writes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent :: ScreenGui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(420, 40)
label.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(255, 200, 120)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function update()
	local status = ReplicatedStorage:GetAttribute("RoundStatus")
	label.Text = if typeof(status) == "string" then status else ""
end

ReplicatedStorage:GetAttributeChangedSignal("RoundStatus"):Connect(update)
update()
