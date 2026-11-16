--!strict
-- How to detect key presses with UserInputService
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-userinputservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ChargeThrow
-- LocalScript in StarterPlayerScripts named ChargeThrow.
-- Hold the right mouse button to charge, release to throw. Press R to check a held key.
local UserInputService = game:GetService("UserInputService")

local MAX_CHARGE_SECONDS = 2

local chargeStarted: number? = nil

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		chargeStarted = os.clock()
	elseif input.KeyCode == Enum.KeyCode.R then
		-- IsKeyDown asks about another key at this moment
		local running = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		print(if running then "Reload while sprinting" else "Reload")
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 and chargeStarted then
		local held = math.min(os.clock() - chargeStarted, MAX_CHARGE_SECONDS)
		chargeStarted = nil
		print(string.format("Thrown with %.0f%% power", held / MAX_CHARGE_SECONDS * 100))
	end
end)
