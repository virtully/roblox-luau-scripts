--!strict
-- How to make a restaurant game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-restaurant-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Kitchen
-- Script in ServerScriptService named Kitchen.
-- Each player's plate lives here. Stations change it; customers check it and pay.
local Players = game:GetService("Players")

local MENU: { [string]: { ingredients: { string }, price: number } } = table.freeze({
	Burger = { ingredients = { "Bun", "Patty", "Lettuce" }, price = 15 },
	Salad = { ingredients = { "Lettuce", "Lettuce" }, price = 8 },
	PlainBurger = { ingredients = { "Bun", "Patty" }, price = 10 },
})
local MAX_ON_PLATE = 5

local plates: { [Player]: { string } } = {}

local function plateOf(player: Player): { string }
	local plate = plates[player]
	if not plate then
		plate = {}
		plates[player] = plate
	end
	return plate
end

local function showPlate(player: Player)
	player:SetAttribute("Plate", table.concat(plateOf(player), ", ")) -- the HUD reads this
end

local function sameIngredients(plate: { string }, needed: { string }): boolean
	if #plate ~= #needed then
		return false
	end
	local counts: { [string]: number } = {}
	for _, item in needed do
		counts[item] = (counts[item] or 0) + 1
	end
	for _, item in plate do
		local left = counts[item]
		if not left or left == 0 then
			return false
		end
		counts[item] = left - 1
	end
	return true
end

local function pay(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cash.Value += amount
	end
end

-- Stations
for _, station in workspace:WaitForChild("Stations"):GetChildren() do
	local prompt = station:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		continue
	end
	prompt.Triggered:Connect(function(player)
		local plate = plateOf(player)
		local gives = station:GetAttribute("Gives")
		if typeof(gives) == "string" then
			if #plate < MAX_ON_PLATE then
				table.insert(plate, gives)
			end
		elseif station.Name == "Stove" then
			local raw = table.find(plate, "RawPatty")
			if raw then
				plate[raw] = "Patty" -- a real game would wait a few seconds here
			end
		elseif station.Name == "Bin" then
			table.clear(plate)
		end
		showPlate(player)
	end)
end

-- Customers
local function setUpCustomer(customer: Instance)
	local prompt = customer:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		local order = customer:GetAttribute("Order")
		local dish = if typeof(order) == "string" then MENU[order] else nil
		if not dish then
			return
		end
		local plate = plateOf(player)
		if not sameIngredients(plate, dish.ingredients) then
			return -- wrong plate: nothing happens, the player can fix it
		end
		table.clear(plate)
		showPlate(player)
		pay(player, dish.price)
		-- next order for this customer (in a full game, a new customer walks in)
		local names: { string } = {}
		for name in MENU do
			table.insert(names, name)
		end
		customer:SetAttribute("Order", names[math.random(1, #names)])
	end)
end

local customers = workspace:WaitForChild("Customers")
for _, customer in customers:GetChildren() do
	setUpCustomer(customer)
end
customers.ChildAdded:Connect(setUpCustomer)

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	leaderstats.Parent = player
	showPlate(player)
end)
Players.PlayerRemoving:Connect(function(player)
	plates[player] = nil
end)
