--!strict
-- Roblox game pass script: sell perks the right way
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-game-pass-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ProductReceipts
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local COINS_100_PRODUCT_ID = 0 -- replace 0 with your developer product ID

-- One function per developer product. Each returns true only once the player has what they paid for.
local productHandlers: { [number]: (player: Player) -> boolean } = {}

productHandlers[COINS_100_PRODUCT_ID] = function(player: Player): boolean
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += 100
		return true
	end
	return false
end

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- The buyer left. Roblox keeps the purchase open and offers it again when they rejoin.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = productHandlers[receiptInfo.ProductId]
	if not handler then
		warn(`No handler for developer product {receiptInfo.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(handler, player)
	if ok and granted == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn(`Could not grant product {receiptInfo.ProductId} to {player.Name}: {granted}`)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set this once, in one server Script, for all of your developer products
MarketplaceService.ProcessReceipt = processReceipt
