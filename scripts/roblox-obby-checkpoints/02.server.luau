--!strict
-- How to make obby checkpoints in Roblox Studio (with saving)
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-obby-checkpoints
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SkipStageProduct
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local SKIP_STAGE_PRODUCT_ID = 0 -- replace with your developer product ID

-- Set ProcessReceipt once, in one server Script, for every developer product in
-- the game. If another script already sets it, move this branch into that one.
-- It is set straight away; the wait for the checkpoint script happens inside it.
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == SKIP_STAGE_PRODUCT_ID then
		-- Created by the ObbyCheckpoints script, which owns the saved stage
		local skipStage = ServerStorage:WaitForChild("SkipStage", 30)
		if not (skipStage and skipStage:IsA("BindableFunction")) then
			warn("SkipStage not found: is the ObbyCheckpoints script running?")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(function()
			return skipStage:Invoke(player, receiptInfo.PurchaseId)
		end)
		if ok and granted == true then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		elseif not ok then
			warn(`Skip stage failed for {player.Name}: {granted}`)
		end
	end

	-- Not saved yet, or a product this script does not handle. Roblox calls
	-- ProcessReceipt again when the player rejoins or buys something else.
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
