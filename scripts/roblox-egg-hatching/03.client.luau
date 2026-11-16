--!strict
-- How to make an egg hatching system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-egg-hatching
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named HatchAnimation
-- LocalScript in StarterPlayerScripts named HatchAnimation.
-- Shows the egg shaking, then the pet's name in its rarity colour.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local hatchedEvent = ReplicatedStorage:WaitForChild("EggHatched") :: RemoteEvent

local RARITY_COLORS: { [string]: Color3 } = {
	Common = Color3.fromRGB(220, 220, 220),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
}

local gui = Instance.new("ScreenGui")
gui.Name = "HatchGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local egg = Instance.new("TextLabel")
egg.AnchorPoint = Vector2.new(0.5, 0.5)
egg.Position = UDim2.fromScale(0.5, 0.45)
egg.Size = UDim2.fromOffset(160, 200)
egg.BackgroundColor3 = Color3.fromRGB(250, 240, 220)
egg.Text = ""
egg.Parent = gui
local eggCorner = Instance.new("UICorner")
eggCorner.CornerRadius = UDim.new(0.5, 0)
eggCorner.Parent = egg

local result = Instance.new("TextLabel")
result.AnchorPoint = Vector2.new(0.5, 0)
result.Position = UDim2.fromScale(0.5, 0.65)
result.Size = UDim2.fromOffset(400, 60)
result.BackgroundTransparency = 1
result.Font = Enum.Font.GothamBlack
result.TextSize = 34
result.TextStrokeTransparency = 0.4
result.Parent = gui

local busy = false

hatchedEvent.OnClientEvent:Connect(function(eggName: string, petName: string?, rarity: string?)
	if not petName then
		-- The server said no: not enough coins
		result.Text = "Not enough coins for " .. eggName
		result.TextColor3 = Color3.fromRGB(255, 110, 110)
		gui.Enabled = true
		egg.Visible = false
		task.wait(1.5)
		gui.Enabled = false
		egg.Visible = true
		return
	end
	if busy then
		return
	end
	busy = true
	gui.Enabled = true
	egg.Visible = true
	egg.Size = UDim2.fromOffset(160, 200)
	result.Text = ""

	-- Shake: rotate left and right a few times, faster each time
	for i = 1, 6 do
		local angle = if i % 2 == 0 then 12 else -12
		local shake = TweenService:Create(egg, TweenInfo.new(0.25 - i * 0.025), { Rotation = angle })
		shake:Play()
		shake.Completed:Wait()
	end
	-- Pop: the egg grows and disappears, the pet's name appears
	local pop = TweenService:Create(egg, TweenInfo.new(0.2), { Size = UDim2.fromOffset(240, 300), Rotation = 0 })
	pop:Play()
	pop.Completed:Wait()
	egg.Visible = false
	result.Text = string.format("%s! (%s)", petName, rarity or "")
	result.TextColor3 = RARITY_COLORS[rarity or ""] or Color3.new(1, 1, 1)
	task.wait(2)
	gui.Enabled = false
	busy = false
end)
