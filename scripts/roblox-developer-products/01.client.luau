--!strict
-- How to make a developer product in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-developer-products
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the BuyCoins button named BuyCoins
-- LocalScript inside the BuyCoins TextButton.
-- Only shows the purchase window. The server gives the coins (Receipts script).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local COINS_100_ID = 0000000 -- your developer product ID

local button = script.Parent :: TextButton

button.Activated:Connect(function()
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, COINS_100_ID)
end)
