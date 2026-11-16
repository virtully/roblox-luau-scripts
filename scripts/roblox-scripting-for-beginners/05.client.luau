--!strict
-- How to script in Roblox Studio: a beginner's guide
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-scripting-for-beginners
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MyFirstLocalScript
-- LocalScript in StarterPlayer > StarterPlayerScripts named MyFirstLocalScript.
-- A LocalScript runs on one player's own device. Press E: the Pad fades on your
-- screen only, because a change to a part made here does not reach the server or anyone else.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
print(`Hello, {player.Name}`) -- shows in Output, marked as Client

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return -- the key was used for something else, such as typing in chat
	end
	if input.KeyCode == Enum.KeyCode.E then
		local pad = workspace:FindFirstChild("Pad")
		if pad and pad:IsA("BasePart") then
			pad.Transparency = if pad.Transparency == 0 then 0.6 else 0
		end
	end
end)
