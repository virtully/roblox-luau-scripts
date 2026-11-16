--!strict
-- How to script in Roblox Studio: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-scripting-for-beginners
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in a Part in Workspace named ColourChanger
-- Script inside a Part in Workspace, named ColourChanger.
-- Scripts change the same properties you see in the Properties window.
-- This one gives its part a new colour every second, for every player.

local part = script.Parent :: BasePart -- the part this script sits inside

local colours = {
	Color3.fromRGB(255, 85, 85), -- red
	Color3.fromRGB(85, 170, 255), -- blue
	Color3.fromRGB(85, 255, 127), -- green
}

part.Anchored = true -- an anchored part stays where you put it

local index = 1
while true do
	part.Color = colours[index]
	index = index % #colours + 1 -- 1, 2, 3, then back to 1
	task.wait(1) -- pause for one second (the old wait() is deprecated)
end
