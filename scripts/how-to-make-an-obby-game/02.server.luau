--!strict
-- How to make an obby game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-obby-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named StageFunnel
-- Script in ServerScriptService named StageFunnel.
-- Logs each stage a player reaches as a funnel step, so the Funnel page in
-- Creator Hub analytics shows the stage where players stop.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local FUNNEL_NAME = "ObbyStages"
local MAX_STEP = 100 -- funnels accept steps 1 to 100

local function watch(player: Player)
	local leaderstats = player:WaitForChild("leaderstats", 30)
	local stage = leaderstats and leaderstats:WaitForChild("Stage", 30)
	if not (stage and stage:IsA("IntValue")) then
		return
	end
	local function log()
		local step = math.clamp(stage.Value, 1, MAX_STEP)
		-- Repeats of a step are ignored by the funnel, so a returning player is fine
		AnalyticsService:LogFunnelStepEvent(player, FUNNEL_NAME, nil, step, "Stage " .. step)
	end
	log()
	stage.Changed:Connect(log)
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end
