--!strict
-- How to make teams in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-team-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named TeamPicker
-- LocalScript in StarterPlayerScripts named TeamPicker.
-- One button per pickable team, in the team's colour, with a live player count.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local chooseTeam = ReplicatedStorage:WaitForChild("ChooseTeam") :: RemoteEvent
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TeamPicker"
gui.ResetOnSpawn = false
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 12)
bar.Size = UDim2.fromOffset(0, 44)
bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.Parent = bar
gui.Parent = player:WaitForChild("PlayerGui")

local buttons: { [Team]: TextButton } = {}

local function refresh()
	for team, button in buttons do
		local count = #team:GetPlayers()
		local mine = player.Team == team
		button.Text = string.format("%s%s (%d)", if mine then "> " else "", team.Name, count)
	end
end

local function addButton(team: Instance)
	if not team:IsA("Team") or team.AutoAssignable then
		return
	end
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(150, 44)
	button.BackgroundColor3 = team.TeamColor.Color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Activated:Connect(function()
		chooseTeam:FireServer(team.Name)
	end)
	button.Parent = bar
	buttons[team] = button
	team.PlayerAdded:Connect(refresh)
	team.PlayerRemoved:Connect(refresh)
	refresh()
end

for _, team in Teams:GetChildren() do
	addButton(team)
end
Teams.ChildAdded:Connect(addButton)
player:GetPropertyChangedSignal("Team"):Connect(refresh)
