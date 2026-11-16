--!strict
-- How to make a shop GUI in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-shop-gui
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ShopService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- What the ShopCatalog module returns, so strict type checking can check the fields we use
type ShopItem = { id: string, name: string, price: number, description: string, toolName: string }
type Catalog = {
	items: { ShopItem },
	get: (id: string) -> ShopItem?,
	ownedAttribute: (id: string) -> string,
}

local ShopCatalog = require(ReplicatedStorage:WaitForChild("ShopCatalog")) :: Catalog
local buyItem = ReplicatedStorage:WaitForChild("ShopRemotes"):WaitForChild("BuyItem") :: RemoteFunction
local shopItems = ServerStorage:WaitForChild("ShopItems")

local COOLDOWN_SECONDS = 0.5
local lastRequest: { [Player]: number } = {}

local function giveTool(player: Player, template: Tool)
	-- Backpack: the player can use the tool straight away
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		template:Clone().Parent = backpack
	end
	-- StarterGear: Roblox copies it into the Backpack again every time the character spawns
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	if starterGear then
		template:Clone().Parent = starterGear
	end
end

local function onBuyItem(player: Player, itemId: unknown): (boolean, string)
	-- 1. The only thing the client sends is an item id, so it must be a string
	if type(itemId) ~= "string" then
		return false, "That item does not exist."
	end

	-- 2. Ignore double clicks and scripted floods of requests
	local now = os.clock()
	local last = lastRequest[player]
	if last and now - last < COOLDOWN_SECONDS then
		return false, "Slow down a little."
	end
	lastRequest[player] = now

	-- 3. Look the item up in the server's own copy of the catalogue
	local item = ShopCatalog.get(itemId)
	if not item then
		return false, "That item does not exist."
	end

	local ownedAttribute = ShopCatalog.ownedAttribute(item.id)
	if player:GetAttribute(ownedAttribute) == true then
		return false, "You already own this."
	end

	local template = shopItems:FindFirstChild(item.toolName)
	if not (template and template:IsA("Tool")) then
		warn(`ShopItems has no Tool named {item.toolName} for shop item {item.id}`)
		return false, "This item is not available right now."
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not (coins and coins:IsA("IntValue")) then
		return false, "Your coins have not loaded yet."
	end

	-- 4. The price comes from the catalogue, never from the client
	if coins.Value < item.price then
		return false, `You need {item.price - coins.Value} more coins.`
	end

	-- 5. Take the coins, then give the item. Nothing here yields, so two requests
	-- from the same player cannot both pass the checks above before this runs.
	coins.Value -= item.price
	giveTool(player, template)
	player:SetAttribute(ownedAttribute, true)

	return true, `You bought {item.name}.`
end

buyItem.OnServerInvoke = onBuyItem

Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
end)
