--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named NotifyClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
local player = Players.LocalPlayer

-- A small banner at the top of the screen, built in code
local gui = Instance.new("ScreenGui")
gui.Name = "Notifications"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 16)
label.Size = UDim2.fromOffset(420, 44)
label.BackgroundColor3 = Color3.fromRGB(18, 11, 31)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Visible = false
label.Parent = gui

local messageCount = 0

-- No player parameter here: the server already chose who receives it
notify.OnClientEvent:Connect(function(message: string)
	messageCount += 1
	local thisMessage = messageCount
	label.Text = message
	label.Visible = true
	task.delay(4, function()
		if messageCount == thisMessage then -- hide it unless a newer message replaced it
			label.Visible = false
		end
	end)
end)
