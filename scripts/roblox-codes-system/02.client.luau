--!strict
-- How to make a codes system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-codes-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CodesMenu
-- LocalScript in StarterPlayerScripts named CodesMenu.
-- A Codes button that opens a box to type a code and redeem it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local redeemFunction = ReplicatedStorage:WaitForChild("RedeemCode") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "CodesGui"
gui.ResetOnSpawn = false

local function corner(parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = parent
end

local openButton = Instance.new("TextButton")
openButton.Text = "Codes"
openButton.Size = UDim2.fromOffset(100, 40)
openButton.Position = UDim2.new(0, 12, 0.5, 0)
openButton.BackgroundColor3 = Color3.fromRGB(110, 80, 220)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 18
corner(openButton)
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(320, 170)
panel.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
panel.Visible = false
corner(panel)
panel.Parent = gui

local box = Instance.new("TextBox")
box.PlaceholderText = "Enter a code"
box.Text = ""
box.ClearTextOnFocus = false
box.Size = UDim2.new(1, -32, 0, 44)
box.Position = UDim2.fromOffset(16, 16)
box.BackgroundColor3 = Color3.fromRGB(50, 44, 66)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 18
corner(box)
box.Parent = panel

local redeemButton = openButton:Clone()
redeemButton.Text = "Redeem"
redeemButton.Size = UDim2.new(1, -32, 0, 40)
redeemButton.Position = UDim2.fromOffset(16, 70)
redeemButton.Parent = panel

local status = Instance.new("TextLabel")
status.Text = ""
status.Size = UDim2.new(1, -32, 0, 40)
status.Position = UDim2.fromOffset(16, 118)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.Font = Enum.Font.Gotham
status.TextSize = 16
status.TextWrapped = true
status.Parent = panel

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	status.Text = ""
end)

local waiting = false
redeemButton.Activated:Connect(function()
	if waiting or box.Text == "" then
		return
	end
	waiting = true
	status.Text = "Checking..."
	-- InvokeServer waits for the server's answer; pcall in case the call fails
	local ok, answer = pcall(function()
		return redeemFunction:InvokeServer(box.Text)
	end)
	status.Text = if ok and typeof(answer) == "string" then answer else "Something went wrong, try again"
	waiting = false
end)
