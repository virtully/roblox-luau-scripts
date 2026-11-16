--!strict
-- How to make a farming game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-farming-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CropServer
-- Script in ServerScriptService named CropServer.
-- Plant, grow and harvest on the server. Growth is worked out from os.time(), so a saved crop grows offline too.
type Crop = { seconds: number, cost: number, sell: number }
local CROPS: { [string]: Crop } = {
	Carrot = { seconds = 30, cost = 5, sell = 12 },
	Pumpkin = { seconds = 300, cost = 40, sell = 130 },
}

local plots = workspace:WaitForChild("Plots") :: Folder -- anchored parts, one per patch of soil

local function coins(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Coins")
	return if value and value:IsA("IntValue") then value else nil
end

-- How far a plot has grown, from 0 to 1, using os.time() saved at planting
local function progress(plot: BasePart): number
	local crop = CROPS[plot:GetAttribute("Crop") :: string]
	local plantedAt = plot:GetAttribute("PlantedAt") :: number?
	if not crop or not plantedAt then
		return 0
	end
	return math.clamp((os.time() - plantedAt) / crop.seconds, 0, 1)
end

local function onPrompt(plot: BasePart, player: Player)
	local wallet = coins(player)
	local owner = plot:GetAttribute("Owner")
	if not wallet or (owner and owner ~= player.UserId) then
		return -- someone else's plot
	end
	local cropName = plot:GetAttribute("Crop") :: string?
	if not cropName then
		local seed = (player:GetAttribute("Seed") :: string?) or "Carrot" -- picked in the seed shop
		local crop = CROPS[seed]
		if crop and wallet.Value >= crop.cost then
			wallet.Value -= crop.cost
			plot:SetAttribute("Owner", player.UserId)
			plot:SetAttribute("Crop", seed)
			plot:SetAttribute("PlantedAt", os.time())
		end
	elseif progress(plot) >= 1 then
		wallet.Value += CROPS[cropName].sell
		plot:SetAttribute("Crop", nil)
		plot:SetAttribute("PlantedAt", nil)
	end
end

for _, plot in plots:GetChildren() do
	if plot:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Plant"
		prompt.Parent = plot
		prompt.Triggered:Connect(function(player)
			onPrompt(plot, player)
		end)
	end
end

-- Once a second: update each prompt's text so players see what pressing E will do
while true do
	for _, plot in plots:GetChildren() do
		local prompt = plot:FindFirstChildOfClass("ProximityPrompt")
		if prompt and plot:IsA("BasePart") then
			local p = progress(plot)
			prompt.ActionText = if not plot:GetAttribute("Crop") then "Plant" elseif p >= 1 then "Harvest" else "Growing"
			prompt.ObjectText = if plot:GetAttribute("Crop") then math.floor(p * 100) .. "%" else ""
		end
	end
	task.wait(1)
end
