--!strict
-- How to make a tool in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tool-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Flashlight Tool named FlashlightScript
-- Script inside the Flashlight Tool, named FlashlightScript.
local tool = script.Parent :: Tool
local handle = tool:WaitForChild("Handle") :: BasePart
local light = handle:WaitForChild("SpotLight") :: SpotLight

light.Enabled = false

tool.Activated:Connect(function()
	light.Enabled = not light.Enabled
end)

tool.Unequipped:Connect(function()
	light.Enabled = false -- off when put away
end)
