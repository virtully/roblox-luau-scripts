--!strict
-- How to detect key presses with UserInputService
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-userinputservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named Keybinds
-- LocalScript in StarterPlayerScripts named Keybinds (Step 4 version).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local useAbilityRemote = ReplicatedStorage:WaitForChild("UseAbility") :: RemoteEvent

local function useAbility()
	useAbilityRemote:FireServer() -- the server decides what happens
end

local ACTIONS: { [Enum.KeyCode]: () -> () } = {
	[Enum.KeyCode.F] = useAbility,
}

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	local action = ACTIONS[input.KeyCode]
	if action then
		action()
	end
end)
