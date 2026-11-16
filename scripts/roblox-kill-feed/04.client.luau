--!strict
-- How to make a kill feed and kill counter in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-feed
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named KillFeedGui
-- LocalScript in StarterGui named KillFeedGui.
-- Shows "Killer eliminated Victim" lines in the top-right for every kill the server reports.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MAX_LINES = 5
local LINE_SECONDS = 6 -- how long a line stays before fading

local player = Players.LocalPlayer
local killFeed = ReplicatedStorage:WaitForChild("KillFeed") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "KillFeed"
gui.ResetOnSpawn = false

local column = Instance.new("Frame")
column.AnchorPoint = Vector2.new(1, 0)
column.Position = UDim2.new(1, -16, 0, 60)
column.Size = UDim2.fromOffset(320, 200)
column.BackgroundTransparency = 1
column.Parent = gui

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Padding = UDim.new(0, 4)
layout.Parent = column

gui.Parent = player:WaitForChild("PlayerGui")

local counter = 0

local function addLine(text: string, mine: boolean)
	counter += 1
	local line = Instance.new("TextLabel")
	line.LayoutOrder = -counter -- newest first
	line.AutomaticSize = Enum.AutomaticSize.X
	line.Size = UDim2.fromOffset(0, 28)
	line.BackgroundColor3 = if mine then Color3.fromRGB(120, 90, 255) else Color3.fromRGB(20, 20, 28)
	line.BackgroundTransparency = 0.25
	line.TextColor3 = Color3.new(1, 1, 1)
	line.Font = Enum.Font.GothamBold
	line.TextSize = 15
	line.Text = "  " .. text .. "  "
	line.Parent = column
	Instance.new("UICorner").Parent = line

	-- Keep only the newest MAX_LINES
	local lines = {}
	for _, child in column:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	table.sort(lines, function(a: TextLabel, b: TextLabel)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = MAX_LINES + 1, #lines do
		lines[i]:Destroy()
	end

	task.delay(LINE_SECONDS, function()
		if line.Parent then
			local fade = TweenService:Create(line, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			line:Destroy()
		end
	end)
end

killFeed.OnClientEvent:Connect(function(killerName: unknown, victimName: unknown, weapon: unknown)
	if type(killerName) ~= "string" or type(victimName) ~= "string" then
		return
	end
	local me = player.DisplayName
	if killerName == "" then
		addLine(victimName .. " died", victimName == me)
		return
	end
	local with = if type(weapon) == "string" and weapon ~= "" then " [" .. weapon .. "]" else ""
	addLine(killerName .. " eliminated " .. victimName .. with, killerName == me or victimName == me)
end)
