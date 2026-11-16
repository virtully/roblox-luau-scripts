--!strict
-- How to make a press E to interact prompt in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-proximity-prompt
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CustomPrompts
-- LocalScript in StarterPlayerScripts named CustomPrompts.
-- Draws a simple label for prompts whose Style is Custom.
local ProximityPromptService = game:GetService("ProximityPromptService")

ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, _inputType: Enum.ProximityPromptInputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 44)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = prompt.Parent :: any

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(30, 24, 46)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "[" .. prompt.KeyboardKeyCode.Name .. "] " .. prompt.ActionText
	label.Parent = billboard

	billboard.Parent = (game:GetService("Players").LocalPlayer :: Player):WaitForChild("PlayerGui")
	prompt.PromptHidden:Once(function()
		billboard:Destroy()
	end)
end)
