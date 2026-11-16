--!strict
-- How to make NPC dialogue in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-dialogue
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named DialogueData
-- ModuleScript in ReplicatedStorage named DialogueData.
-- Every conversation, keyed by the NPC's name in Workspace.NPCs. Each line has the
-- NPC's text and the player's choices. A choice can lead to another line (next),
-- end the talk (no next) and ask the server to do something (action). If the server
-- cannot do the action, it shows the failNext line instead of next.

export type Choice = {
	text: string,
	next: string?, -- the line to show after this choice; nil ends the conversation
	action: string?, -- a server action from DialogueService's ACTIONS table
	item: string?, -- for the GiveItem action: a Tool's name in ServerStorage.DialogueItems
	failNext: string?, -- the line to show instead of next when the action could not be done
}

export type Line = {
	text: string,
	choices: { Choice },
}

local DialogueData: { [string]: { [string]: Line } } = {
	Guide = {
		start = {
			text = "Welcome to the village! What can I do for you?",
			choices = {
				{ text = "Any tips?", next = "tips" },
				{ text = "I'm hurt. Can you help?", next = "healed", action = "Heal", failNext = "healTooSoon" },
				{ text = "Got anything for the cave?", next = "torch", action = "GiveItem", item = "Torch", failNext = "hasTorch" },
				{ text = "Bye!" },
			},
		},
		tips = {
			text = "Stay off the red bricks, and come back if you get hurt.",
			choices = {
				{ text = "Anything else?", next = "start" },
				{ text = "Thanks!" },
			},
		},
		healed = {
			text = "There you go, good as new.",
			choices = {
				{ text = "Thank you!" },
			},
		},
		torch = {
			text = "Take this torch. The cave is dark.",
			choices = {
				{ text = "Thanks!" },
			},
		},
		healTooSoon = {
			text = "I healed you a moment ago. Come back in a little while.",
			choices = {
				{ text = "OK" },
			},
		},
		hasTorch = {
			text = "You already have my torch. Keep it lit!",
			choices = {
				{ text = "Will do!" },
			},
		},
	},
}

return DialogueData
