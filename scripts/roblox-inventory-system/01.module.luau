--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named ItemCatalog
-- Every item that can exist in the game. The server and every client read this
-- list; only the server decides who owns what.
export type Item = {
	id: string, -- must match the key below
	name: string,
	description: string,
	maxStack: number, -- the most of this item that fits in one slot
	icon: string?, -- optional image, written as "rbxassetid://" plus your image's ID
	toolName: string?, -- a Tool in ServerStorage.ItemTools: the item can be equipped
	heal: number?, -- health restored on use: the item is a consumable
}

local items: { [string]: Item } = {
	sword = {
		id = "sword",
		name = "Sword",
		description = "Equip it to put it in your hand.",
		maxStack = 1,
		toolName = "Sword",
	},
	apple = {
		id = "apple",
		name = "Apple",
		description = "Use it to restore 25 health.",
		maxStack = 10,
		heal = 25,
	},
	wood = {
		id = "wood",
		name = "Wood",
		description = "A building material.",
		maxStack = 50,
	},
}

local ItemCatalog = {}

-- Returns the item with this id, or nil if no such item exists
function ItemCatalog.get(id: string): Item?
	return items[id]
end

return ItemCatalog
