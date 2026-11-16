--!strict
-- How to make an admin panel in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-admin-panel-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named AdminPanel
-- LocalScript in StarterPlayer > StarterPlayerScripts named AdminPanel.
-- Builds the panel only for players with a rank. It sends requests; the server decides.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("AdminRemote") :: RemoteFunction

local ok, info = pcall(function()
	return remote:InvokeServer(nil)
end)
if not ok or type(info) ~= "table" or (tonumber(info.rank) or 0) < 1 then
	return -- not staff: no panel at all
end
local reasons: { string } = if type(info.reasons) == "table" then info.reasons else { "Breaking the game rules" }

local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(parent: Instance, text: string, y: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(16, y)
	l.Size = UDim2.new(1, -32, 0, 18)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 14
	l.TextColor3 = Color3.fromRGB(170, 175, 190)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = parent
	return l
end

local function box(parent: Instance, placeholder: string, y: number): TextBox
	local b = Instance.new("TextBox")
	b.Position = UDim2.fromOffset(16, y)
	b.Size = UDim2.new(1, -32, 0, 36)
	b.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.PlaceholderText = placeholder
	b.PlaceholderColor3 = Color3.fromRGB(120, 125, 140)
	b.Font = Enum.Font.Gotham
	b.TextSize = 16
	b.Text = ""
	b.ClearTextOnFocus = false
	b.Parent = parent
	corner(b, 8)
	return b
end

local function button(parent: Instance, text: string, color: Color3, x: number, y: number, width: number): TextButton
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(x, if x > 0 then 4 else 16, 0, y)
	b.Size = UDim2.new(width, -20, 0, 38)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 8)
	return b
end

-- The toggle button, top right of the screen
local toggle = button(gui, "Admin", Color3.fromRGB(90, 70, 200), 0, 0, 0)
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -16, 0, 60)
toggle.Size = UDim2.fromOffset(90, 36)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 104)
panel.Size = UDim2.fromOffset(320, 372)
panel.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local title = label(panel, "Admin panel  ·  " .. tostring(info.rankName), 12)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

label(panel, "Player name, or a user ID to ban or unban", 40)
local targetBox = box(panel, "Name or user ID", 60)
label(panel, "Ban length in minutes (empty = permanent)", 104)
local minutesBox = box(panel, "60", 124)

label(panel, "Reason the player sees", 168)
local reasonIndex = 1
local reasonButton = button(panel, reasons[1], Color3.fromRGB(45, 48, 62), 0, 188, 1)

local kickButton = button(panel, "Kick", Color3.fromRGB(220, 140, 40), 0, 240, 0.5)
local banButton = button(panel, "Ban", Color3.fromRGB(210, 60, 70), 0.5, 240, 0.5)
local unbanButton = button(panel, "Unban user ID", Color3.fromRGB(60, 150, 90), 0, 286, 1)

local status = label(panel, "", 336)
status.TextWrapped = true
status.Size = UDim2.new(1, -32, 0, 30)

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

reasonButton.Activated:Connect(function()
	reasonIndex = reasonIndex % #reasons + 1
	reasonButton.Text = reasons[reasonIndex]
end)

local busy = false
local function send(action: string)
	if busy then
		return
	end
	busy = true
	status.Text = "Working..."
	local sent, result = pcall(function()
		return remote:InvokeServer({
			action = action,
			target = targetBox.Text,
			reason = reasons[reasonIndex],
			minutes = tonumber(minutesBox.Text),
		})
	end)
	status.Text = if sent and type(result) == "table" then tostring(result.message) else "No answer from the server."
	busy = false
end

kickButton.Activated:Connect(function()
	send("kick")
end)
banButton.Activated:Connect(function()
	send("ban")
end)
unbanButton.Activated:Connect(function()
	send("unban")
end)
