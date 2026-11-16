--!strict
-- How to make a trading system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-trading-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PlayerItems
-- Script in ServerScriptService named PlayerItems.
-- Gives every player an Items folder. Each IntValue inside is an item; its Value is how many.
local Players = game:GetService("Players")

-- Items to start with, for testing trades. Replace with your own game's items.
local STARTER_ITEMS: { [string]: number } = {
	Sword = 1,
	Shield = 1,
	Gem = 5,
}

Players.PlayerAdded:Connect(function(player: Player)
	local items = Instance.new("Folder")
	items.Name = "Items"
	for itemName, count in STARTER_ITEMS do
		local item = Instance.new("IntValue")
		item.Name = itemName
		item.Value = count
		item.Parent = items
	end
	items.Parent = player
end)
