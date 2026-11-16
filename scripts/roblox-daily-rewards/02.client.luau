--!strict
-- How to make daily rewards in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-daily-rewards
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named DailyRewardsMenu
-- LocalScript in StarterPlayerScripts named DailyRewardsMenu.
-- A Daily button with a countdown. When the reward is ready it says Claim.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local statusFunction = ReplicatedStorage:WaitForChild("GetDailyStatus") :: RemoteFunction
local claimFunction = ReplicatedStorage:WaitForChild("ClaimDaily") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "DailyGui"
gui.ResetOnSpawn = false
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(170, 48)
button.Position = UDim2.new(0, 12, 0.5, 52)
button.BackgroundColor3 = Color3.fromRGB(240, 170, 40)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 17
button.Text = "Daily reward"
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button
button.Parent = gui
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local readyAt: number? = nil -- os.clock() time when the reward is ready
local day = 1
local busy = false

local function refresh()
	local ok, status = pcall(function()
		return statusFunction:InvokeServer()
	end)
	if ok and type(status) == "table" and type(status.wait) == "number" then
		readyAt = os.clock() + status.wait
		day = if type(status.day) == "number" then status.day else 1
	end
end

local function format(seconds: number): string
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

button.Activated:Connect(function()
	if busy or not readyAt or os.clock() < readyAt then
		return
	end
	busy = true
	button.Text = "Claiming..."
	local ok, message = pcall(function()
		return claimFunction:InvokeServer()
	end)
	button.Text = if ok and type(message) == "string" then message else "Try again"
	task.wait(2)
	refresh()
	busy = false
end)

refresh()
while true do
	if not busy then
		if not readyAt then
			button.Text = "Loading..."
			refresh()
		elseif os.clock() >= readyAt then
			button.Text = string.format("Claim day %d!", day)
		else
			button.Text = "Next: " .. format(math.ceil(readyAt - os.clock()))
		end
	end
	task.wait(1)
end
