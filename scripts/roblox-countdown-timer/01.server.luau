--!strict
-- How to make a countdown timer in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-countdown-timer
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Countdown
-- Script in ServerScriptService named Countdown.
-- Runs intermission and round countdowns. Clients show them from the EndsAt and Label attributes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local INTERMISSION_SECONDS = 15
local ROUND_SECONDS = 120
local MIN_PLAYERS = 2 -- the round ends early when fewer are left in it

local countdown = Instance.new("Folder")
countdown.Name = "Countdown"
countdown.Parent = ReplicatedStorage

-- Shows a countdown on every screen and waits for it on the server.
-- stopEarly is checked four times a second; when it returns true the countdown ends at once.
local function runCountdown(label: string, seconds: number, stopEarly: (() -> boolean)?)
	local endsAt = workspace:GetServerTimeNow() + seconds
	countdown:SetAttribute("Label", label)
	countdown:SetAttribute("EndsAt", endsAt)
	countdown:SetAttribute("PausedLeft", nil)
	while workspace:GetServerTimeNow() < endsAt do
		if stopEarly and stopEarly() then
			break
		end
		task.wait(0.25)
		-- Paused (Step 3): hold here until another script resumes
		while countdown:GetAttribute("PausedLeft") ~= nil do
			task.wait(0.25)
		end
		-- Another script can add time by changing EndsAt (see "Add time" below)
		local current = countdown:GetAttribute("EndsAt")
		if type(current) == "number" then
			endsAt = current
		end
	end
	-- Show 0:00 on every screen, even if the countdown ended early
	countdown:SetAttribute("EndsAt", workspace:GetServerTimeNow())
end

-- Players taking part in the current round
local inRound: { Player } = {}

local function roundIsOver(): boolean
	-- Remove players who left or died, then check how many are left
	for i = #inRound, 1, -1 do
		local player = inRound[i]
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 then
			table.remove(inRound, i)
		end
	end
	return #inRound < MIN_PLAYERS
end

while true do
	-- Wait for enough players before counting anything
	if #Players:GetPlayers() < MIN_PLAYERS then
		countdown:SetAttribute("Label", "Waiting for players")
		countdown:SetAttribute("EndsAt", nil)
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= MIN_PLAYERS
	end

	runCountdown("Intermission", INTERMISSION_SECONDS)

	-- Start the round: put your own code here (teleport players to the map, give tools...)
	inRound = Players:GetPlayers()

	runCountdown("Round", ROUND_SECONDS, roundIsOver)

	-- End the round: put your own code here (pick the winner, teleport everyone back...)
	countdown:SetAttribute("Label", if #inRound == 1 then inRound[1].DisplayName .. " wins!" else "Round over")
	task.wait(4)
end
