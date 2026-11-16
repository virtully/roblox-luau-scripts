--!strict
-- How to make a countdown timer in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-countdown-timer
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named TimerDisplay
-- LocalScript in StarterGui named TimerDisplay.
-- Counts down to the server's EndsAt attribute every frame, using the shared server clock.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local WARNING_SECONDS = 10 -- turn red for the last few seconds
local NORMAL_COLOR = Color3.new(1, 1, 1)
local WARNING_COLOR = Color3.fromRGB(255, 80, 80)

local countdown = ReplicatedStorage:WaitForChild("Countdown")

local gui = Instance.new("ScreenGui")
gui.Name = "TimerGui"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(260, 44)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
label.BackgroundTransparency = 0.2
label.TextColor3 = NORMAL_COLOR
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Parent = gui
Instance.new("UICorner").Parent = label

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local lastText = ""

RunService.RenderStepped:Connect(function()
	local title = countdown:GetAttribute("Label")
	local endsAt = countdown:GetAttribute("EndsAt")
	local pausedLeft = countdown:GetAttribute("PausedLeft")
	local text = if type(title) == "string" then title else ""
	local secondsLeft: number? = nil

	if type(pausedLeft) == "number" then
		local left = math.ceil(pausedLeft)
		secondsLeft = left
		text ..= "  " .. formatTime(left) .. " (paused)"
	elseif type(endsAt) == "number" then
		-- The same clock the server uses, so every player sees the same number
		local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		secondsLeft = left
		text ..= "  " .. formatTime(left)
	end

	-- Only touch the label when the text changes, not 60 times a second
	if text ~= lastText then
		lastText = text
		label.Text = text
		label.TextColor3 = if secondsLeft and secondsLeft <= WARNING_SECONDS then WARNING_COLOR else NORMAL_COLOR
	end
end)
