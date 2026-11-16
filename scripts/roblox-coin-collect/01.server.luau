--!strict
-- How to make collectable coins in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-coin-collect
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CoinPickups
-- Script in ServerScriptService named CoinPickups.
-- Every part tagged "Coin" gives coins when a player touches it, hides, then comes back.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local COIN_VALUE = 1 -- coins per pickup (a coin part can override it with a "Value" attribute)
local RESPAWN_SECONDS = 10 -- how long a collected coin stays hidden

-- leaderstats: the Coins column in the player list
Players.PlayerAdded:Connect(function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
	leaderstats.Parent = player
end)

local function addCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
	end
end

local function setUpCoin(coin: Instance)
	if not coin:IsA("BasePart") then
		return
	end
	local collected = false
	coin.Touched:Connect(function(hit: BasePart)
		if collected then
			return
		end
		local character = hit.Parent
		if not (character and character:IsA("Model")) then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not (player and humanoid and humanoid.Health > 0) then
			return
		end
		collected = true
		local value = coin:GetAttribute("Value")
		addCoins(player, if typeof(value) == "number" then value else COIN_VALUE)

		-- Hide the coin for everyone, then bring it back
		local oldTransparency = coin.Transparency
		coin.Transparency = 1
		coin.CanTouch = false
		task.delay(RESPAWN_SECONDS, function()
			coin.Transparency = oldTransparency
			coin.CanTouch = true
			collected = false
		end)
	end)
end

for _, coin in CollectionService:GetTagged("Coin") do
	setUpCoin(coin)
end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(setUpCoin)
