--!strict
-- How to make a typewriter text effect in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-typewriter-text
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named DialogueBox
-- ModuleScript in ReplicatedStorage named DialogueBox. Use it from LocalScripts:
--   DialogueBox.show("Guide", { "Hi!", "Welcome to the island." })  returns when the player closes it
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

type TypewriterModule = {
	play: (label: TextLabel, text: string, options: { speed: number?, sound: Sound? }?) -> (),
	skip: (label: TextLabel) -> (),
	isTyping: (label: TextLabel) -> boolean,
}
local Typewriter = require(ReplicatedStorage:WaitForChild("Typewriter")) :: TypewriterModule

local TYPE_SPEED = 40 -- characters per second
local found = ReplicatedStorage:FindFirstChild("TypeBlip")
local blip: Sound? = if found and found:IsA("Sound") then found else nil

-- Build the box once, the first time this module is required
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogueBox"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- The whole box is one TextButton, so a click or tap anywhere on it counts
local box = Instance.new("TextButton")
box.Name = "Box"
box.Text = ""
box.AutoButtonColor = false
box.AnchorPoint = Vector2.new(0.5, 1)
box.Position = UDim2.new(0.5, 0, 1, -24)
box.Size = UDim2.new(0.9, 0, 0, 150)
box.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
box.BackgroundTransparency = 0.1
box.Visible = false
box.Parent = screenGui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(720, 150)
sizeLimit.Parent = box

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = box

local nameLabel = Instance.new("TextLabel")
nameLabel.BackgroundTransparency = 1
nameLabel.Position = UDim2.fromOffset(20, 12)
nameLabel.Size = UDim2.new(1, -40, 0, 26)
nameLabel.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
nameLabel.TextSize = 22
nameLabel.TextColor3 = Color3.fromRGB(255, 205, 90)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = box

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(20, 44)
body.Size = UDim2.new(1, -40, 1, -76)
body.FontFace = Font.fromEnum(Enum.Font.BuilderSans)
body.TextSize = 20
body.TextColor3 = Color3.new(1, 1, 1)
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Parent = box

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(1, 1)
hint.Position = UDim2.new(1, -16, 1, -8)
hint.Size = UDim2.fromOffset(200, 20)
hint.FontFace = Font.fromEnum(Enum.Font.BuilderSans)
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(170, 165, 190)
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Text = "Click to continue"
hint.Parent = box

-- Clicks, taps, Enter and the gamepad X button all mean "next"
local advance = Instance.new("BindableEvent")
box.Activated:Connect(function()
	advance:Fire()
end)
UserInputService.InputBegan:Connect(function(input: InputObject, processedByUI: boolean)
	if processedByUI or not box.Visible then
		return
	end
	if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonX then
		advance:Fire()
	end
end)

local open = false
local DialogueBox = {}

function DialogueBox.show(speaker: string, lines: { string })
	if open then
		return -- one conversation at a time
	end
	open = true
	nameLabel.Text = speaker
	box.Visible = true

	for _, line in lines do
		hint.Visible = false
		task.spawn(function()
			Typewriter.play(body, line, { speed = TYPE_SPEED, sound = blip })
			hint.Visible = true
		end)
		-- First press: if the line is still typing, finish it and wait for a second press
		advance.Event:Wait()
		if Typewriter.isTyping(body) then
			Typewriter.skip(body)
			advance.Event:Wait()
		end
	end

	box.Visible = false
	open = false
end

return DialogueBox
