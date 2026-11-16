--!strict
-- How to make a combat system with hitboxes in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-combat-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CombatClient
-- LocalScript in StarterPlayerScripts named CombatClient.
-- Click, tap the Punch button or press R2 on a gamepad to punch.
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local punchEvent = ReplicatedStorage:WaitForChild("Punch") :: RemoteEvent

local function onPunch(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		punchEvent:FireServer()
	end
	-- Pass, so clicks still reach buttons and tools
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Punch", onPunch, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("Punch", "Punch")
