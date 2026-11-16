--!strict
-- How to detect key presses with UserInputService
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-userinputservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named AbilityAction
-- LocalScript in StarterPlayerScripts named AbilityAction.
-- One action for the F key, the X button on a gamepad and an on-screen button on phones.
local ContextActionService = game:GetService("ContextActionService")

local ACTION_NAME = "UseAbility"

local function onAbility(_actionName: string, inputState: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		print("Ability used")
	end
	return Enum.ContextActionResult.Sink -- this press is handled; nothing else gets it
end

-- true = create a touch button on phones and tablets
ContextActionService:BindAction(ACTION_NAME, onAbility, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle(ACTION_NAME, "Use")
