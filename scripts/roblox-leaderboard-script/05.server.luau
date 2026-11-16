--!strict
-- How to make a leaderboard in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-leaderboard-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named KillStats
local Players = game:GetService("Players")

-- Adds Kills, Deaths and Minutes to the leaderstats folder that your
-- Leaderstats script makes. Weapons record the attacker on the victim's
-- Humanoid with SetAttribute("LastHitBy", attacker.UserId) before damage.

local function addStat(leaderstats: Instance, name: string): IntValue
	local existing = leaderstats:FindFirstChild(name)
	if existing and existing:IsA("IntValue") then
		return existing
	end
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Parent = leaderstats
	return stat
end

local function getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat and stat:IsA("IntValue") then
		return stat
	end
	return nil
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	humanoid.Died:Connect(function()
		local deaths = getStat(player, "Deaths")
		if deaths then
			deaths.Value += 1
		end

		local attackerId = humanoid:GetAttribute("LastHitBy")
		if typeof(attackerId) ~= "number" or attackerId == player.UserId then
			return -- no attacker recorded, or the player killed themselves
		end
		local attacker = Players:GetPlayerByUserId(attackerId)
		local kills = attacker and getStat(attacker, "Kills")
		if kills then
			kills.Value += 1
		end
	end)
end

local function onPlayerAdded(player: Player)
	local leaderstats = player:WaitForChild("leaderstats", 30)
	if not leaderstats then
		warn(`No leaderstats for {player.Name}, so no kill stats`)
		return
	end
	addStat(leaderstats, "Kills")
	addStat(leaderstats, "Deaths")
	addStat(leaderstats, "Minutes")

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- One minute of play time for everyone in the server, every minute
while true do
	task.wait(60)
	for _, player in Players:GetPlayers() do
		local minutes = getStat(player, "Minutes")
		if minutes then
			minutes.Value += 1
		end
	end
end
