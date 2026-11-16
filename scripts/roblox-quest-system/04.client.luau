--!strict
-- How to make a quest system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-quest-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named QuestPanel
-- LocalScript in StarterGui named QuestPanel.
-- Shows the current quest from the attributes the server sets. It never changes progress.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

type Quest = {
	title: string,
	kind: "Collect" | "Defeat",
	target: string,
	amount: number,
	reward: number,
}

local quests = require(ReplicatedStorage:WaitForChild("QuestConfig")) :: { Quest }
local questCompleted = ReplicatedStorage:WaitForChild("QuestCompleted") :: RemoteEvent
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "QuestGui"
gui.ResetOnSpawn = false

local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(16, 80)
panel.Size = UDim2.fromOffset(240, 74)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.BackgroundTransparency = 0.15
panel.Parent = gui
Instance.new("UICorner").Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 22)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = panel

local count = Instance.new("TextLabel")
count.Position = UDim2.fromOffset(12, 30)
count.Size = UDim2.new(1, -24, 0, 18)
count.BackgroundTransparency = 1
count.TextXAlignment = Enum.TextXAlignment.Left
count.TextColor3 = Color3.fromRGB(200, 200, 210)
count.Font = Enum.Font.Gotham
count.TextSize = 14
count.Parent = panel

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(12, 54)
barBack.Size = UDim2.new(1, -24, 0, 8)
barBack.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
barBack.Parent = panel
Instance.new("UICorner").Parent = barBack

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
bar.Parent = barBack
Instance.new("UICorner").Parent = bar

gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	local index = player:GetAttribute("QuestIndex")
	local progress = player:GetAttribute("QuestProgress")
	if type(index) ~= "number" or type(progress) ~= "number" then
		title.Text = "Loading quests..."
		count.Text = ""
		return
	end
	local quest = quests[index]
	if not quest then
		title.Text = "All quests done"
		count.Text = "Nice work!"
		bar.Size = UDim2.fromScale(1, 1)
		return
	end
	title.Text = quest.title
	count.Text = progress .. " / " .. quest.amount .. "   Reward: " .. quest.reward .. " coins"
	TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.fromScale(progress / quest.amount, 1) }):Play()
end

questCompleted.OnClientEvent:Connect(function(questTitle: string, reward: number)
	title.Text = "Quest complete: " .. questTitle
	count.Text = "+" .. reward .. " coins"
	bar.Size = UDim2.fromScale(1, 1)
	task.wait(2)
	refresh()
end)

player:GetAttributeChangedSignal("QuestIndex"):Connect(refresh)
player:GetAttributeChangedSignal("QuestProgress"):Connect(refresh)
refresh()
