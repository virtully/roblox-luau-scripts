--!strict
-- How to make a typewriter text effect in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-typewriter-text
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named Typewriter
-- ModuleScript in ReplicatedStorage named Typewriter. Use it from LocalScripts:
--   Typewriter.play(label, text, options)  types the text and returns when it is done or skipped
--   Typewriter.skip(label)                 shows the rest of the text at once
local SoundService = game:GetService("SoundService")

local DEFAULT_SPEED = 40 -- characters per second
local SOUND_EVERY = 2 -- play the blip every this many letters

-- Extra seconds to wait after these characters, so sentences breathe
local PAUSES: { [string]: number } = {
	["."] = 0.3,
	["!"] = 0.3,
	["?"] = 0.3,
	[","] = 0.12,
	[":"] = 0.12,
}

export type Options = {
	speed: number?, -- characters per second
	sound: Sound?, -- a short blip to play while typing
}

type State = { skip: boolean }

-- One entry per label that is typing right now
local running: { [TextLabel]: State } = {}

local Typewriter = {}

function Typewriter.play(label: TextLabel, text: string, options: Options?)
	local speed = if options and options.speed then options.speed else DEFAULT_SPEED
	local sound = if options then options.sound else nil

	-- A new line on the same label replaces the old one: the old loop sees it is no longer current and stops
	local state: State = { skip = false }
	running[label] = state

	-- Split the text into graphemes first, so the loop can look at each one
	local characters: { string } = {}
	for first, last in utf8.graphemes(text) do
		table.insert(characters, string.sub(text, first, last))
	end

	label.Text = text
	label.MaxVisibleGraphemes = 0
	local shown = 0
	local budget = 0 -- seconds of typing we are allowed to catch up on

	while shown < #characters do
		if state.skip or running[label] ~= state then
			break
		end
		-- Show as many characters as the time since the last frame allows, so the speed
		-- is the same at 30 or 240 frames a second
		while shown < #characters and budget >= 0 do
			shown += 1
			local character = characters[shown]
			budget -= 1 / speed + (PAUSES[character] or 0)
			if sound and character ~= " " and shown % SOUND_EVERY == 0 then
				SoundService:PlayLocalSound(sound)
			end
		end
		label.MaxVisibleGraphemes = shown
		budget += task.wait()
	end

	if running[label] == state then
		label.MaxVisibleGraphemes = -1
		running[label] = nil
	end
end

function Typewriter.skip(label: TextLabel)
	local state = running[label]
	if state then
		state.skip = true
	end
end

function Typewriter.isTyping(label: TextLabel): boolean
	return running[label] ~= nil
end

return Typewriter
