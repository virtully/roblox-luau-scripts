--!strict
-- How to make a Grow a Garden style game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-grow-a-garden-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SeedShopStock
-- Script in ServerScriptService named SeedShopStock.
-- The seed shop restocks every 5 minutes. The stock is rolled from the clock, so
-- every server shows the same seeds at the same time without talking to each other.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RESTOCK_SECONDS = 300
type Offer = { seed: string, chance: number, maxStock: number }
local OFFERS: { Offer } = {
	{ seed = "Carrot", chance = 1, maxStock = 20 }, -- always in stock
	{ seed = "Melon", chance = 0.4, maxStock = 5 },
	{ seed = "Starfruit", chance = 0.05, maxStock = 1 }, -- in about 1 restock in 20
}

local shop = Instance.new("Folder")
shop.Name = "SeedShop"
shop.Parent = ReplicatedStorage

local function restock(window: number)
	-- Same window number on every server, so the same rolls on every server
	local rng = Random.new(window)
	for _, offer in OFFERS do
		local inStock = rng:NextNumber() < offer.chance
		local amount = if inStock then rng:NextInteger(1, offer.maxStock) else 0
		shop:SetAttribute(offer.seed, amount)
	end
	shop:SetAttribute("NextRestock", (window + 1) * RESTOCK_SECONDS) -- for a countdown on screen
end

local current = -1
while true do
	local window = os.time() // RESTOCK_SECONDS
	if window ~= current then
		current = window
		restock(window)
	end
	task.wait(1)
end
