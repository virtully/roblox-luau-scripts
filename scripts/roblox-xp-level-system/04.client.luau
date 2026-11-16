--!strict
-- How to make an XP and level system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-xp-level-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named XpBar
-- LocalScript in StarterGui named XpBar.
-- Draws "Level 3" and a bar that fills as the player earns XP. It only reads values.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local level = leaderstats:WaitForChild("Level") :: IntValue
local xp = leaderstats:WaitForChild("XP") :: IntValue

local gui = Instance.new("ScreenGui")
gui.Name = "XpBarGui"
gui.ResetOnSpawn = false

local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -16)
back.Size = UDim2.fromOffset(320, 22)
back.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
back.Parent = gui
Instance.new("UICorner").Parent = back

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
fill.Parent = back
Instance.new("UICorner").Parent = fill

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Parent = back

gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	local needed = player:GetAttribute("XpNeeded")
	if type(needed) ~= "number" or needed <= 0 then
		-- Max level, or the server has not sent the number yet
		fill.Size = UDim2.fromScale(1, 1)
		label.Text = "Level " .. level.Value
		return
	end
	local ratio = math.clamp(xp.Value / needed, 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(ratio, 1) }):Play()
	label.Text = "Level " .. level.Value .. "   " .. xp.Value .. " / " .. needed .. " XP"
end

level.Changed:Connect(refresh)
xp.Changed:Connect(refresh)
player:GetAttributeChangedSignal("XpNeeded"):Connect(refresh)
refresh()
