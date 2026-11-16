--!strict
-- How to make a Grow a Garden style game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-grow-a-garden-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GardenGrowth
-- Script in ServerScriptService named GardenGrowth.
-- Soil parts tagged "Soil" (with an OwnerId attribute set when a plot is given out)
-- grow plants by the clock: a plant stores when it was planted, not a timer.
local CollectionService = game:GetService("CollectionService")

type Seed = { growSeconds: number, value: number }
local SEEDS: { [string]: Seed } = {
	Carrot = { growSeconds = 60, value = 10 },
	Melon = { growSeconds = 600, value = 90 },
	Starfruit = { growSeconds = 3600, value = 700 },
}
local GOLDEN_CHANCE = 0.02 -- 2 in 100 harvests are Golden, worth 5 times as much

-- 0 when planted, 1 when ripe. os.time() keeps counting while the owner is away.
local function growth(soil: Instance): number
	local seed = SEEDS[tostring(soil:GetAttribute("Seed"))]
	local plantedAt = tonumber(soil:GetAttribute("PlantedAt"))
	if not seed or not plantedAt then
		return 0
	end
	return math.clamp((os.time() - plantedAt) / seed.growSeconds, 0, 1)
end

local function setUpSoil(soil: Instance)
	if not soil:IsA("BasePart") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Plant"
	prompt.Parent = soil
	prompt.Triggered:Connect(function(player: Player)
		if soil:GetAttribute("OwnerId") ~= player.UserId then
			return -- only the plot's owner
		end
		local planted = soil:GetAttribute("Seed")
		if planted == nil then
			local held = tostring(player:GetAttribute("HeldSeed"))
			local count = tonumber(player:GetAttribute("Seeds_" .. held)) or 0
			if SEEDS[held] and count > 0 then
				player:SetAttribute("Seeds_" .. held, count - 1)
				soil:SetAttribute("Seed", held)
				soil:SetAttribute("PlantedAt", os.time())
			end
		elseif growth(soil) >= 1 then
			local seed = SEEDS[tostring(planted)]
			local golden = math.random() < GOLDEN_CHANCE
			local weight = 0.8 + math.random() * 0.7 -- a heavier fruit sells for more
			local price = math.floor(seed.value * weight * (if golden then 5 else 1))
			player:SetAttribute("FruitValue", (tonumber(player:GetAttribute("FruitValue")) or 0) + price)
			soil:SetAttribute("Seed", nil)
			soil:SetAttribute("PlantedAt", nil)
		end
	end)
end

for _, soil in CollectionService:GetTagged("Soil") do
	setUpSoil(soil)
end
CollectionService:GetInstanceAddedSignal("Soil"):Connect(setUpSoil)

-- Share each plant's growth with clients so a LocalScript can scale the plant model
while true do
	task.wait(1)
	for _, soil in CollectionService:GetTagged("Soil") do
		soil:SetAttribute("Growth", growth(soil))
	end
end
