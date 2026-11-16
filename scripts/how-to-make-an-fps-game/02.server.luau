--!strict
-- How to make an FPS game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-fps-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named KillScore
-- Script in ServerScriptService named KillScore.
-- Credits each kill to the last enemy who hit the victim and ends the match
-- when someone reaches the score. Your weapon script must tag hits:
-- target:SetAttribute("LastHitBy", player.UserId) right before TakeDamage.
local Players = game:GetService("Players")

local SCORE_TO_WIN = 25
local matchOver = false

local function getKills(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	return if kills and kills:IsA("IntValue") then kills else nil
end

local function endMatch(winner: Player)
	matchOver = true -- kills stop counting until the next match
	workspace:SetAttribute("LastWinner", winner.Name)
	task.wait(8) -- time to show the result screen
	for _, player in Players:GetPlayers() do
		local kills = getKills(player)
		if kills then
			kills.Value = 0
		end
		task.spawn(player.LoadCharacterAsync, player)
	end
	matchOver = false
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Once(function()
			local killerId = humanoid:GetAttribute("LastHitBy")
			local killer = if typeof(killerId) == "number" then Players:GetPlayerByUserId(killerId) else nil
			local killerKills = killer and getKills(killer)
			local enemies = killer and killer ~= player and (not killer.Team or killer.Team ~= player.Team)
			if killer and killerKills and enemies and not matchOver then
				killerKills.Value += 1
				if killerKills.Value >= SCORE_TO_WIN then
					endMatch(killer)
				end
			end
		end)
	end)
end)
