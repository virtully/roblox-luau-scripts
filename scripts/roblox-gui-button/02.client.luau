--!strict
-- How to make a GUI button that opens a menu in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gui-button
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the ClaimButton named ClaimButton
-- LocalScript inside the ClaimButton TextButton.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimReward = ReplicatedStorage:WaitForChild("ClaimReward") :: RemoteEvent
local button = script.Parent :: TextButton

button.Activated:Connect(function()
	claimReward:FireServer()
	button.Text = "Claimed!"
	button.Active = false
	button.AutoButtonColor = false
end)
