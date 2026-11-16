--!strict
-- How to make a rebirth system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-rebirth-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named RebirthButton
-- LocalScript in StarterGui named RebirthButton.
-- Shows the price and multiplier, and asks the server to rebirth. It never sends numbers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local requestRebirth = ReplicatedStorage:WaitForChild("RequestRebirth") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "RebirthGui"
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 0.5)
button.Position = UDim2.new(1, -16, 0.5, 0)
button.Size = UDim2.fromOffset(200, 64)
button.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.TextWrapped = true
button.Parent = gui
Instance.new("UICorner").Parent = button

gui.Parent = player:WaitForChild("PlayerGui")

local busy = false

local function refresh()
	if busy then
		return
	end
	local cost = player:GetAttribute("RebirthCost")
	local multiplier = player:GetAttribute("CoinMultiplier")
	if type(cost) == "number" and type(multiplier) == "number" then
		button.Text = "Rebirth: " .. cost .. " coins (now x" .. multiplier .. ")"
	else
		button.Text = "Loading..."
	end
end

button.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	local ok, _, message = pcall(function()
		return requestRebirth:InvokeServer()
	end)
	if ok and type(message) == "string" then
		button.Text = message
	else
		button.Text = "Try again"
	end
	task.wait(1.5)
	busy = false
	refresh()
end)

player:GetAttributeChangedSignal("RebirthCost"):Connect(refresh)
player:GetAttributeChangedSignal("CoinMultiplier"):Connect(refresh)
refresh()
