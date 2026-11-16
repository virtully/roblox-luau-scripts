--!strict
-- How to make a typewriter text effect in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-typewriter-text
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named SignDialogue
-- LocalScript in StarterPlayerScripts named SignDialogue.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type DialogueBoxModule = {
	show: (speaker: string, lines: { string }) -> (),
}
local DialogueBox = require(ReplicatedStorage:WaitForChild("DialogueBox")) :: DialogueBoxModule

local sign = workspace:WaitForChild("Sign")
local prompt = sign:WaitForChild("ProximityPrompt") :: ProximityPrompt

local LINES = {
	"Welcome, traveller. This island has been quiet for a hundred years.",
	"Something woke up in the caves last night...",
	"If you go in, take a torch. And do not touch the glowing crystals!",
}

prompt.Triggered:Connect(function()
	prompt.Enabled = false -- hide the prompt while the box is open
	DialogueBox.show("Old Sign", LINES)
	prompt.Enabled = true
end)
