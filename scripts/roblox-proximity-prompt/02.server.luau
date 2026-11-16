--!strict
-- How to make a press E to interact prompt in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-proximity-prompt
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PromptRouter
-- Script in ServerScriptService named PromptRouter.
-- Handles every ProximityPrompt that has an "Action" attribute.
local ProximityPromptService = game:GetService("ProximityPromptService")

local handlers: { [string]: (player: Player, prompt: ProximityPrompt) -> () } = {
	Heal = function(player: Player, _prompt: ProximityPrompt)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
		end
	end,
	Ring = function(_player: Player, prompt: ProximityPrompt)
		local sound = prompt.Parent and prompt.Parent:FindFirstChildOfClass("Sound")
		if sound then
			sound:Play()
		end
	end,
}

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local action = prompt:GetAttribute("Action")
	local handler = if typeof(action) == "string" then handlers[action] else nil
	if handler then
		handler(player, prompt)
	end
end)
