--!strict
-- How to make a fishing system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-fishing-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the FishingRod Tool named RodClient
-- LocalScript inside the FishingRod Tool, named RodClient.
-- Click with the rod to cast. A label above the screen says what happened.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent :: Tool
local castEvent = ReplicatedStorage:WaitForChild("CastLine") :: RemoteEvent
local resultEvent = ReplicatedStorage:WaitForChild("FishingResult") :: RemoteEvent

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 70)
label.Size = UDim2.fromOffset(320, 40)
label.BackgroundColor3 = Color3.fromRGB(20, 40, 70)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Visible = false
local gui = Instance.new("ScreenGui")
gui.Name = "FishingGui"
gui.ResetOnSpawn = false
label.Parent = gui
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function show(text: string, seconds: number?)
	label.Text = text
	label.Visible = true
	if seconds then
		task.delay(seconds, function()
			if label.Text == text then
				label.Visible = false
			end
		end)
	end
end

tool.Activated:Connect(function()
	castEvent:FireServer()
end)

resultEvent.OnClientEvent:Connect(function(kind: string, fishName: string?, coins: number?)
	if kind == "far" then
		show("Get closer to the water", 2)
	elseif kind == "cast" then
		show("Waiting for a bite...")
	elseif kind == "caught" and fishName and coins then
		show(string.format("You caught a %s! +%d coins", fishName, coins), 3)
	end
end)
