--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named InventoryService
-- The only code that changes inventories. It sits in ServerScriptService,
-- where clients can neither see nor run it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Strict mode cannot follow a require through WaitForChild, so we state
-- the part of the module this script uses
type Item = { id: string, maxStack: number }
type Catalog = { get: (id: string) -> Item? }
local ItemCatalog = require(ReplicatedStorage:WaitForChild("ItemCatalog")) :: Catalog

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local inventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent

export type Slot = { id: string, count: number }
type Inventory = { slots: { Slot }, capacity: number, equipped: string? }

local CAPACITY = 20 -- slots per player
local STARTER_ITEMS: { Slot } = { -- what a brand new player starts with
	{ id = "sword", count = 1 },
	{ id = "apple", count = 3 },
}

local inventories: { [Player]: Inventory } = {}

local InventoryService = {}

-- Sends the owner a copy of their inventory. Runs after every change.
local function sync(player: Player)
	local inventory = inventories[player]
	if inventory then
		inventoryUpdated:FireClient(player, {
			capacity = inventory.capacity,
			slots = inventory.slots,
			equipped = inventory.equipped,
		})
	end
end

-- Stacking rules: top up stacks that are not full, then start new stacks in
-- empty slots. Returns how many were added, which can be less than asked.
local function addToInventory(inventory: Inventory, item: Item, amount: number): number
	local remaining = amount
	for _, slot in inventory.slots do
		if remaining == 0 then
			break
		end
		if slot.id == item.id and slot.count < item.maxStack then
			local moved = math.min(item.maxStack - slot.count, remaining)
			slot.count += moved
			remaining -= moved
		end
	end
	while remaining > 0 and #inventory.slots < inventory.capacity do
		local moved = math.min(item.maxStack, remaining)
		table.insert(inventory.slots, { id = item.id, count = moved })
		remaining -= moved
	end
	return amount - remaining
end

function InventoryService.count(player: Player, itemId: string): number
	local inventory = inventories[player]
	local total = 0
	if inventory then
		for _, slot in inventory.slots do
			if slot.id == itemId then
				total += slot.count
			end
		end
	end
	return total
end

-- How many more of an item fit: space left in its stacks plus empty slots
function InventoryService.spaceFor(player: Player, itemId: string): number
	local inventory = inventories[player]
	local item = ItemCatalog.get(itemId)
	if not inventory or not item then
		return 0
	end
	local space = (inventory.capacity - #inventory.slots) * item.maxStack
	for _, slot in inventory.slots do
		if slot.id == itemId then
			space += item.maxStack - slot.count
		end
	end
	return space
end

-- Adds up to `amount` of an item. Returns how many were added (0 if the
-- item does not exist, the inventory is full or has not loaded yet).
function InventoryService.add(player: Player, itemId: string, amount: number): number
	local inventory = inventories[player]
	local item = ItemCatalog.get(itemId)
	local wanted = math.floor(amount)
	if not inventory or not item or wanted < 1 then
		return 0
	end
	local added = addToInventory(inventory, item, wanted)
	if added > 0 then
		sync(player)
	end
	return added
end

-- Removes exactly `amount` of an item, taking from the last stacks first.
-- If the player has fewer than that, removes nothing and returns false.
function InventoryService.remove(player: Player, itemId: string, amount: number): boolean
	local inventory = inventories[player]
	local wanted = math.floor(amount)
	if not inventory or wanted < 1 or InventoryService.count(player, itemId) < wanted then
		return false
	end
	local remaining = wanted
	-- Walk backwards so table.remove never skips a slot
	for index = #inventory.slots, 1, -1 do
		local slot = inventory.slots[index]
		if slot.id == itemId then
			local taken = math.min(slot.count, remaining)
			slot.count -= taken
			remaining -= taken
			if slot.count == 0 then
				table.remove(inventory.slots, index)
			end
			if remaining == 0 then
				break
			end
		end
	end
	sync(player)
	return true
end

function InventoryService.getEquipped(player: Player): string?
	local inventory = inventories[player]
	return if inventory then inventory.equipped else nil
end

function InventoryService.setEquipped(player: Player, itemId: string?)
	local inventory = inventories[player]
	if inventory then
		inventory.equipped = itemId
		sync(player)
	end
end

-- Called once a player's saved data has loaded. `saved` is whatever the data
-- store returned: nil for a new player. Every entry goes back through the
-- stacking rules, so removed items and old stack sizes cannot break anything.
function InventoryService.load(player: Player, saved: any)
	local inventory: Inventory = { slots = {}, capacity = CAPACITY }
	local entries: { Slot } = STARTER_ITEMS
	if type(saved) == "table" and type(saved.slots) == "table" then
		entries = {}
		for _, entry in saved.slots do
			if type(entry) == "table" and type(entry.id) == "string" and type(entry.count) == "number" then
				table.insert(entries, { id = entry.id, count = math.floor(entry.count) })
			end
		end
	end
	for _, entry in entries do
		local item = ItemCatalog.get(entry.id)
		if item and entry.count > 0 then
			addToInventory(inventory, item, entry.count)
		end
	end
	inventories[player] = inventory
	sync(player)
end

-- A plain copy to save, or nil if this player's data never loaded
function InventoryService.serialize(player: Player): { version: number, slots: { Slot } }?
	local inventory = inventories[player]
	if not inventory then
		return nil
	end
	local slots: { Slot } = {}
	for index, slot in inventory.slots do
		slots[index] = { id = slot.id, count = slot.count }
	end
	return { version = 1, slots = slots }
end

function InventoryService.unload(player: Player)
	inventories[player] = nil
end

return InventoryService
