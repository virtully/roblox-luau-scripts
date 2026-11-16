--!strict
-- How to make a developer product in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-developer-products
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Receipts
-- Script in ServerScriptService named Receipts.
-- The ONLY script that sets MarketplaceService.ProcessReceipt.
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local purchaseHistory = DataStoreService:GetDataStore("PurchaseHistory_v1")

local function addCoins(player: Player, amount: number): boolean
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
		return true
	end
	return false -- leaderstats not ready yet: the purchase stays pending and comes back later
end

-- product ID -> grant function. Return true ONLY once the item is really given.
-- These run inside UpdateAsync, so they must not wait or yield.
local PRODUCTS: { [number]: (player: Player) -> boolean } = {
	[0000000] = function(player: Player): boolean -- 100 Coins
		return addCoins(player, 100)
	end,
	[1111111] = function(player: Player): boolean -- Full heal
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
			return true
		end
		return false
	end,
}

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local purchaseId = tostring(receiptInfo.PurchaseId)
	local ok, recorded = pcall(function()
		return purchaseHistory:UpdateAsync(purchaseId, function(alreadyGranted: boolean?): boolean?
			if alreadyGranted then
				return true -- delivered again after an earlier grant: do not grant twice
			end
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			local grant = PRODUCTS[receiptInfo.ProductId]
			if not (player and grant and grant(player) == true) then
				return nil -- cancel the write: the purchase stays pending and is retried
			end
			return true
		end)
	end)
	if ok and recorded == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if not ok then
		warn("[Receipts] purchase " .. purchaseId .. " not processed:", recorded)
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt
