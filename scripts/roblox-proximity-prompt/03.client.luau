--!strict
-- How to make a press E to interact prompt in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-proximity-prompt
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ChestPromptVisibility
-- LocalScript in StarterPlayerScripts named ChestPromptVisibility.
-- Hides a chest's prompt for this player once the server marks it opened.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function refresh(chest: Instance)
	local prompt = chest:FindFirstChild("ChestPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = player:GetAttribute("Opened_" .. chest.Name) ~= true
	end
end

local function watch(chest: Instance)
	chest.ChildAdded:Connect(function()
		refresh(chest)
	end)
	player:GetAttributeChangedSignal("Opened_" .. chest.Name):Connect(function()
		refresh(chest)
	end)
	refresh(chest)
end

for _, chest in CollectionService:GetTagged("Chest") do
	watch(chest)
end
CollectionService:GetInstanceAddedSignal("Chest"):Connect(watch)
