--!strict
-- How to use attributes in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-attributes
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named LevelWatcher
-- LocalScript in StarterPlayerScripts named LevelWatcher.
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function show()
	print("You are level", player:GetAttribute("Level"))
end

player:GetAttributeChangedSignal("Level"):Connect(show)
show() -- also show the value it already has
