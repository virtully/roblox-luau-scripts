--!strict
-- How to make a survival game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-survival-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Crafting
-- Script in ServerScriptService named Crafting.
-- The inventory lives here, on the server. Clients ask to craft a recipe by name.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local craft = ReplicatedStorage:WaitForChild("Craft") :: RemoteFunction

type Recipe = { needs: { [string]: number }, gives: string, amount: number }

local RECIPES: { [string]: Recipe } = table.freeze({
	Axe = { needs = { Wood = 2, Stone = 1 }, gives = "Axe", amount = 1 },
	Campfire = { needs = { Wood = 4, Stone = 2 }, gives = "Campfire", amount = 1 },
	Wall = { needs = { Wood = 6 }, gives = "Wall", amount = 1 },
})

local inventories: { [Player]: { [string]: number } } = {}

local function inventoryOf(player: Player): { [string]: number }
	local inventory = inventories[player]
	if not inventory then
		inventory = { Wood = 0, Stone = 0 }
		inventories[player] = inventory
	end
	return inventory
end

-- Other server scripts (resource nodes, food) call this to add or remove items.
local function addItem(player: Player, item: string, amount: number)
	local inventory = inventoryOf(player)
	inventory[item] = math.max(0, (inventory[item] or 0) + amount)
	player:SetAttribute("Item_" .. item, inventory[item]) -- the HUD reads these
end

craft.OnServerInvoke = function(player: Player, recipeName: unknown): (boolean, string)
	if typeof(recipeName) ~= "string" then
		return false, "Unknown recipe"
	end
	local recipe = RECIPES[recipeName]
	if not recipe then
		return false, "Unknown recipe"
	end
	local inventory = inventoryOf(player)
	for item, count in recipe.needs do
		if (inventory[item] or 0) < count then
			return false, `Need {count} {item}`
		end
	end
	-- no yields between the check and the change, so two requests cannot both pass
	for item, count in recipe.needs do
		addItem(player, item, -count)
	end
	addItem(player, recipe.gives, recipe.amount)
	return true, `Crafted {recipe.amount} {recipe.gives}`
end

Players.PlayerAdded:Connect(function(player)
	addItem(player, "Wood", 0) -- creates the inventory and the first attributes
end)
Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil -- save it first, once saving is added
end)
