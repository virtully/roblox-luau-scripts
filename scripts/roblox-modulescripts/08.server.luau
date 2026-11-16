--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named CoinPickups
-- Script in ServerScriptService named CoinPickups.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

type CoinServiceModule = {
	get: (player: Player) -> number,
	add: (player: Player, amount: number) -> (),
	spend: (player: Player, amount: number) -> boolean,
}
local CoinService = require(ServerScriptService:WaitForChild("CoinService")) :: CoinServiceModule

local COIN_VALUE = 10

local function setUpCoin(coin: Instance)
	if not coin:IsA("BasePart") then
		return
	end
	local taken = false
	coin.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
		if player and not taken then
			taken = true
			CoinService.add(player, COIN_VALUE)
			coin:Destroy()
		end
	end)
end

for _, coin in CollectionService:GetTagged("Coin") do
	setUpCoin(coin)
end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(setUpCoin)
