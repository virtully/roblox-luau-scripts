--!strict
-- How to detect key presses with UserInputService
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-userinputservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named Keybinds
-- LocalScript in StarterPlayerScripts named Keybinds.
-- Runs a function when the player presses a key, but not while they type in chat.
local UserInputService = game:GetService("UserInputService")

local function useAbility()
	print("Ability used")
end

local function dropItem()
	print("Item dropped")
end

-- One line per key. Add more keys here.
local ACTIONS: { [Enum.KeyCode]: () -> () } = {
	[Enum.KeyCode.F] = useAbility,
	[Enum.KeyCode.Q] = dropItem,
}

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return -- typing in chat or a TextBox, or pressing a button
	end
	local action = ACTIONS[input.KeyCode]
	if action then
		action()
	end
end)
