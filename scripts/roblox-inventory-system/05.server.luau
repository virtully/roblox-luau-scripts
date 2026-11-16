--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named InventoryActions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

type Item = { id: string, toolName: string?, heal: number? }
type Catalog = { get: (id: string) -> Item? }
type InventoryApi = {
	count: (player: Player, itemId: string) -> number,
	remove: (player: Player, itemId: string, amount: number) -> boolean,
	getEquipped: (player: Player) -> string?,
	setEquipped: (player: Player, itemId: string?) -> (),
}
local ItemCatalog = require(ReplicatedStorage:WaitForChild("ItemCatalog")) :: Catalog
local InventoryService = require(ServerScriptService:WaitForChild("InventoryService")) :: InventoryApi

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local equipItem = remotes:WaitForChild("EquipItem") :: RemoteEvent
local useItem = remotes:WaitForChild("UseItem") :: RemoteEvent
local itemTools = ServerStorage:WaitForChild("ItemTools")

local COOLDOWN_SECONDS = 0.25
local lastRequest: { [Player]: number } = {}

-- Every request starts here. A client can send anything at any time, so check
-- the type, that the item exists, that the player owns one, and the rate.
local function ownedItem(player: Player, itemId: unknown): Item?
	if typeof(itemId) ~= "string" then
		return nil
	end
	local now = os.clock()
	if now - (lastRequest[player] or 0) < COOLDOWN_SECONDS then
		return nil
	end
	lastRequest[player] = now
	local item = ItemCatalog.get(itemId)
	if not item or InventoryService.count(player, itemId) < 1 then
		return nil
	end
	return item
end

-- Destroys this item's Tool wherever a copy is: hotbar, hand or StarterGear
local function destroyTools(container: Instance?, itemId: string)
	if not container then
		return
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("InventoryItem") == itemId then
			child:Destroy()
		end
	end
end

local function unequip(player: Player)
	local equippedId = InventoryService.getEquipped(player)
	if equippedId then
		destroyTools(player:FindFirstChildOfClass("Backpack"), equippedId)
		destroyTools(player.Character, equippedId)
		destroyTools(player:FindFirstChildOfClass("StarterGear"), equippedId)
		InventoryService.setEquipped(player, nil)
	end
end

local function equip(player: Player, item: Item, toolName: string)
	local template = itemTools:FindFirstChild(toolName)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not template or not template:IsA("Tool") or not backpack then
		warn(`Cannot equip {item.id}: no Tool named {toolName} in ServerStorage.ItemTools`)
		return
	end
	unequip(player) -- one equipped tool at a time

	local tool = template:Clone()
	tool.CanBeDropped = false -- a dropped copy could be picked up by someone else
	tool:SetAttribute("InventoryItem", item.id)
	tool.Parent = backpack

	-- A second copy in StarterGear is copied back into the Backpack after a respawn
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	if starterGear then
		local gearCopy = tool:Clone()
		gearCopy.Parent = starterGear
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:EquipTool(tool) -- put it straight in their hand
	end
	InventoryService.setEquipped(player, item.id)
end

equipItem.OnServerEvent:Connect(function(player: Player, itemId: unknown)
	local item = ownedItem(player, itemId)
	if not item or not item.toolName then
		return
	end
	if InventoryService.getEquipped(player) == item.id then
		unequip(player) -- clicking the equipped item again takes it away
	else
		equip(player, item, item.toolName)
	end
end)

useItem.OnServerEvent:Connect(function(player: Player, itemId: unknown)
	local item = ownedItem(player, itemId)
	if not item or not item.heal then
		return
	end
	local heal = item.heal
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return -- dead or already at full health: do not waste the item
	end
	-- Take the item first, and only heal if that worked
	if InventoryService.remove(player, item.id, 1) then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
end)
