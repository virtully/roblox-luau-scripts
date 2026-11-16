--!strict
-- How to make a story game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-story-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named StoryDirector
-- Script in ServerScriptService named StoryDirector.
-- Runs the story as a list of steps, the same for every player in the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storyEvent = ReplicatedStorage:WaitForChild("StoryEvent") :: RemoteEvent
local voteEvent = ReplicatedStorage:WaitForChild("VoteEvent") :: RemoteEvent
local zones = workspace:WaitForChild("Zones")

type Step =
	{ kind: "say", speaker: string, text: string, seconds: number }
	| { kind: "goal", text: string, zone: string }
	| { kind: "vote", question: string, options: { string }, seconds: number, key: string }
	| { kind: "ending", name: string }

local choices: { [string]: string } = {} -- vote key -> winning option

local function say(speaker: string, text: string, seconds: number)
	storyEvent:FireAllClients("say", speaker, text)
	task.wait(seconds)
end

local function waitForZone(goalText: string, zoneName: string)
	local zone = zones:WaitForChild(zoneName) :: BasePart
	storyEvent:FireAllClients("goal", goalText)
	local reached = false
	local connection = zone.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorWhichIsA("Model")
		if character and Players:GetPlayerFromCharacter(character) then
			reached = true
		end
	end)
	repeat
		task.wait(0.25)
	until reached
	connection:Disconnect()
end

local function runVote(question: string, options: { string }, seconds: number): string
	local votes: { [Player]: string } = {}
	local connection = voteEvent.OnServerEvent:Connect(function(player, option)
		if typeof(option) == "string" and table.find(options, option) then
			votes[player] = option -- one vote per player; a new vote replaces the old one
		end
	end)
	storyEvent:FireAllClients("vote", question, options, seconds)
	task.wait(seconds)
	connection:Disconnect()

	local counts: { [string]: number } = {}
	for _, option in votes do
		counts[option] = (counts[option] or 0) + 1
	end
	local winner = options[1] -- no votes: the first option
	for _, option in options do
		if (counts[option] or 0) > (counts[winner] or 0) then
			winner = option
		end
	end
	storyEvent:FireAllClients("result", question, winner)
	return winner
end

local function runSteps(steps: { Step })
	for _, step in steps do
		if step.kind == "say" then
			say(step.speaker, step.text, step.seconds)
		elseif step.kind == "goal" then
			waitForZone(step.text, step.zone)
		elseif step.kind == "vote" then
			choices[step.key] = runVote(step.question, step.options, step.seconds)
		elseif step.kind == "ending" then
			storyEvent:FireAllClients("ending", step.name)
		end
	end
end

-- The story as data. Branches are separate lists picked by a choice.
local chapterOne: { Step } = {
	{ kind = "say", speaker = "Narrator", text = "The storm is coming. Get to the shelter.", seconds = 4 },
	{ kind = "goal", text = "Reach the shelter", zone = "Shelter" },
	{ kind = "vote", question = "Open the gate for the stranger?", options = { "Open it", "Keep it shut" }, seconds = 15, key = "stranger" },
}
local helpedEnding: { Step } = {
	{ kind = "say", speaker = "Stranger", text = "Thank you. I know a way out.", seconds = 4 },
	{ kind = "goal", text = "Follow the stranger to the gate", zone = "Gate" },
	{ kind = "ending", name = "Escaped together" },
}
local aloneEnding: { Step } = {
	{ kind = "say", speaker = "Narrator", text = "The knocking stops. The night is long.", seconds = 4 },
	{ kind = "ending", name = "Alone in the dark" },
}

-- Wait for the party, then play the story once.
while #Players:GetPlayers() == 0 do
	task.wait(1)
end
task.wait(5) -- time for everyone in the party to load
runSteps(chapterOne)
runSteps(if choices.stranger == "Open it" then helpedEnding else aloneEnding)
