--!strict
-- How to make a shop GUI in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-shop-gui
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named ShopCatalog
export type ShopItem = {
	id: string, -- saved in data stores later: never change it once players own the item
	name: string, -- shown on the card; safe to change
	price: number, -- in Coins
	description: string,
	toolName: string, -- the Tool in ServerStorage.ShopItems that the player receives
}

-- Cards appear in this order
local items: { ShopItem } = {
	{
		id = "sword",
		name = "Classic Sword",
		price = 50,
		description = "A basic sword for close fights.",
		toolName = "ClassicSword",
	},
	{
		id = "flashlight",
		name = "Flashlight",
		price = 25,
		description = "Lights up dark corners.",
		toolName = "Flashlight",
	},
	{
		id = "grapple",
		name = "Grapple Hook",
		price = 150,
		description = "Reach high ledges.",
		toolName = "GrappleHook",
	},
	{
		id = "speedcoil",
		name = "Speed Coil",
		price = 300,
		description = "Run faster while you hold it.",
		toolName = "SpeedCoil",
	},
}

local byId: { [string]: ShopItem } = {}
for _, item in items do
	byId[item.id] = item
end

local ShopCatalog = {}

ShopCatalog.items = items

-- Returns the item with this id, or nil if there is no such item
function ShopCatalog.get(id: string): ShopItem?
	return byId[id]
end

-- The Player attribute the server sets to true when the player owns an item
function ShopCatalog.ownedAttribute(id: string): string
	return "Owns_" .. id
end

return ShopCatalog
