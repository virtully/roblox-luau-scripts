--!strict
-- Roblox shift to sprint script for PC, mobile and console
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-sprint-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named MovementCheck
-- Players' devices move their own characters, so an exploiter can set any WalkSpeed.
-- This check measures how far each character really moves and warns in the Output
-- when someone keeps going faster than sprinting and dashing allow. It only warns:
-- lag, teleports and conveyors can all look like speeding, so tune it before you punish anyone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

type Config = { SPRINT_BONUS: number, DASH_SPEED: number, DASH_SECONDS: number }
local Config = require(ReplicatedStorage:WaitForChild("MovementConfig")) :: Config

local CHECK_EVERY = 0.5 -- seconds
-- Sprint speed plus room for lag. Raise it if you sell speed boosts.
local SPEED_ALLOWANCE = (StarterPlayer.CharacterWalkSpeed + Config.SPRINT_BONUS) * 1.25
local BURST_ALLOWANCE = Config.DASH_SPEED * Config.DASH_SECONDS * 2 -- room for a dash or two
local DRAIN_PER_CHECK = BURST_ALLOWANCE / 8 -- how fast past bursts are forgiven

local lastPosition: { [Player]: Vector3 } = {}
local lastRoot: { [Player]: BasePart } = {} -- the root part lastPosition was measured on
local excess: { [Player]: number } = {} -- studs moved beyond the allowance, slowly forgiven

Players.PlayerRemoving:Connect(function(player: Player)
	lastPosition[player] = nil
	lastRoot[player] = nil
	excess[player] = nil
end)

while true do
	task.wait(CHECK_EVERY)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			local position = rootPart.Position
			-- A respawn is a new root part, and a server teleport (a round start, a checkpoint)
			-- sets the attribute below: start measuring again instead of flagging the jump
			local previous = if lastRoot[player] == rootPart then lastPosition[player] else nil
			if player:GetAttribute("MovementCheckSkip") then
				player:SetAttribute("MovementCheckSkip", nil)
				previous = nil
			end
			lastPosition[player] = position
			lastRoot[player] = rootPart
			if previous then
				-- Only horizontal movement: falling fast is not cheating
				local moved = Vector3.new(position.X - previous.X, 0, position.Z - previous.Z).Magnitude
				local extra = moved - SPEED_ALLOWANCE * CHECK_EVERY
				local total = math.max(0, (excess[player] or 0) + extra - DRAIN_PER_CHECK)
				excess[player] = total
				if total > BURST_ALLOWANCE then
					warn(`MovementCheck: {player.Name} moved {math.round(moved / CHECK_EVERY)} studs/s`)
					excess[player] = 0
				end
			end
		else
			lastPosition[player] = nil
			lastRoot[player] = nil
		end
	end
end
