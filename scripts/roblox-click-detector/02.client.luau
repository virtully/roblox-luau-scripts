--!strict
-- How to use a ClickDetector in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-click-detector
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ButtonHover
-- LocalScript in StarterPlayerScripts named ButtonHover.
-- Outlines the Button part while this player's cursor is over it.
local button = workspace:WaitForChild("Button") :: BasePart
local clickDetector = button:WaitForChild("ClickDetector") :: ClickDetector

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.Enabled = false
highlight.Adornee = button
highlight.Parent = button

clickDetector.MouseHoverEnter:Connect(function()
	highlight.Enabled = true
end)

clickDetector.MouseHoverLeave:Connect(function()
	highlight.Enabled = false
end)
