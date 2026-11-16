--!strict
-- Luau tables and loops in Roblox: a beginner's guide
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-luau-tables-and-loops
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named RealLoops
-- Script in ServerScriptService named RealLoops.
local Players = game:GetService("Players")

-- 1. Every player in the server: heal them all
for _, player in Players:GetPlayers() do
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

-- 2. Every child of a folder: make each part in a "Lava" folder glow
local lavaFolder = workspace:FindFirstChild("Lava")
if lavaFolder then
	for _, child in lavaFolder:GetChildren() do
		if child:IsA("BasePart") then
			child.Material = Enum.Material.Neon
		end
	end
end

-- 3. A list of tables: a shop catalog, sorted by price
type Item = { name: string, price: number }
local catalog: { Item } = {
	{ name = "Speed Coil", price = 300 },
	{ name = "Sword", price = 150 },
	{ name = "Jetpack", price = 900 },
}
table.sort(catalog, function(a: Item, b: Item): boolean
	return a.price < b.price -- true when a should come before b
end)
for position, item in catalog do
	print(position, item.name, item.price) --> 1 Sword 150, 2 Speed Coil 300, 3 Jetpack 900
end
