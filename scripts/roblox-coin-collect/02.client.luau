--!strict
-- How to make collectable coins in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-coin-collect
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CoinSpin
-- LocalScript in StarterPlayerScripts named CoinSpin.
-- Spins every coin on each player's own screen, so the server does no work for it.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SPIN_DEGREES_PER_SECOND = 90

RunService.RenderStepped:Connect(function(deltaTime: number)
	local turn = CFrame.Angles(0, math.rad(SPIN_DEGREES_PER_SECOND * deltaTime), 0)
	for _, coin in CollectionService:GetTagged("Coin") do
		if coin:IsA("BasePart") and coin.Anchored then
			coin.CFrame = coin.CFrame * turn
		end
	end
end)
