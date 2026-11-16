--!strict
-- How to fix Roblox script errors
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named DeathMessage
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Broken version:
--   local character = player:WaitForChild("Character")
-- Character is a property of Player, not a child, so Output warns:
--   Infinite yield possible on 'Players.YourName:WaitForChild("Character")'

local function onCharacterAdded(character: Model)
	-- With a time-out, WaitForChild returns nil instead of waiting forever
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		warn(`[DeathMessage] no Humanoid in {character:GetFullName()} after 10 seconds`)
		return
	end
	humanoid.Died:Connect(function()
		print(`[DeathMessage] {player.Name} died`)
	end)
end

-- Handle the character that may already exist, then every respawn
local current = player.Character
if current then
	onCharacterAdded(current)
end
player.CharacterAdded:Connect(onCharacterAdded)
