--!strict
-- How to use a ClickDetector in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-click-detector
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Button part named ClickButton
-- Script inside the Button part, named ClickButton.
-- Lights up when clicked, then can be pressed again after a cooldown.
local button = script.Parent :: BasePart
local clickDetector = button:WaitForChild("ClickDetector") :: ClickDetector

local COOLDOWN_SECONDS = 2
local OFF_COLOR = Color3.fromRGB(200, 40, 40)
local ON_COLOR = Color3.fromRGB(40, 200, 80)

local pressedAt = -math.huge
button.Color = OFF_COLOR

clickDetector.MouseClick:Connect(function(player: Player)
	local now = os.clock()
	if now - pressedAt < COOLDOWN_SECONDS then
		return
	end
	-- cheats can fire clicks from any distance, so check it here
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or (root.Position - button.Position).Magnitude > clickDetector.MaxActivationDistance + 5 then
		return
	end
	pressedAt = now
	print(player.Name, "pressed the button")

	button.Color = ON_COLOR
	task.delay(COOLDOWN_SECONDS, function()
		button.Color = OFF_COLOR
	end)
end)
