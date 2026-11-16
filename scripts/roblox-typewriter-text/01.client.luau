--!strict
-- How to make a typewriter text effect in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-typewriter-text
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in a TextLabel in StarterGui named TypeText
-- LocalScript inside a TextLabel, named TypeText. Types the label's own text once.
local label = script.Parent :: TextLabel

local SECONDS_PER_LETTER = 0.03

label.MaxVisibleGraphemes = 0
local shown = 0
for _ in utf8.graphemes(label.Text) do
	shown += 1
	label.MaxVisibleGraphemes = shown
	task.wait(SECONDS_PER_LETTER)
end
label.MaxVisibleGraphemes = -1 -- show everything, whatever happens to the count
