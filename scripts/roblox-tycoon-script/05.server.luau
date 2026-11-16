--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TycoonCollectors
local Players = game:GetService("Players")

local tycoons = workspace:WaitForChild("Tycoons")

local function ownerIdOf(tycoon: Instance): number
	local id = tycoon:GetAttribute("OwnerId")
	return if typeof(id) == "number" then id else 0
end

local function cashOf(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		return cash
	end
	return nil
end

local function setUpCollector(tycoon: Model, collector: BasePart)
	collector.Touched:Connect(function(hit: BasePart)
		-- Only drops made by this plot's droppers count. Characters, tools and
		-- drops from a neighbour's plot are ignored.
		local drops = tycoon:FindFirstChild("Drops")
		if drops == nil or hit.Parent ~= drops then
			return
		end

		local value = hit:GetAttribute("Value")
		-- Destroy sets Parent to nil, so a second touch from the same drop fails the check above
		hit:Destroy()

		local owner = Players:GetPlayerByUserId(ownerIdOf(tycoon))
		local cash = owner and cashOf(owner)
		if cash and typeof(value) == "number" then
			cash.Value += math.floor(value)
		end
	end)
end

for _, tycoon in tycoons:GetChildren() do
	local collector = tycoon:FindFirstChild("Collector")
	if tycoon:IsA("Model") and collector and collector:IsA("BasePart") then
		setUpCollector(tycoon, collector)
	else
		warn(`{tycoon:GetFullName()} needs a Part named Collector`)
	end
end
