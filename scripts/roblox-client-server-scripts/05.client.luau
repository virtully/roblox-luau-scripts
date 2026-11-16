--!strict
-- LocalScript vs Script vs ModuleScript in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-client-server-scripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named RewardClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

type Settings = { AMOUNT: number, COOLDOWN: number }
local RewardSettings = require(ReplicatedStorage:WaitForChild("RewardSettings")) :: Settings
local claimReward = ReplicatedStorage:WaitForChild("ClaimReward") :: RemoteEvent

local player = Players.LocalPlayer
local nextClaim = 0

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.R then
		return -- typing in chat, or a different key
	end
	local now = os.clock()
	if now < nextClaim then
		print(`Next reward in {math.ceil(nextClaim - now)} seconds`)
		return
	end
	nextClaim = now + RewardSettings.COOLDOWN
	claimReward:FireServer() -- ask; the server decides
end)

-- The server changes the attribute, and the change replicates here
player:GetAttributeChangedSignal("Coins"):Connect(function()
	print(`{player.Name} has {player:GetAttribute("Coins")} coins`)
end)
