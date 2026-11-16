--!strict
-- How to make a kill feed and kill counter in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-kill-feed
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named KillTracker
-- Script in ServerScriptService named KillTracker.
-- Kills and Deaths in leaderstats from creator tags, and a kill feed event for every player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SHOW_PLAIN_DEATHS = true -- "Name died" when nobody gets the kill
local XP_PER_KILL = 50 -- used only if the AwardXp event exists

local killFeed = Instance.new("RemoteEvent")
killFeed.Name = "KillFeed"
killFeed.Parent = ReplicatedStorage

local function getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat and stat:IsA("IntValue") then
		return stat
	end
	return nil
end

local function onDied(victim: Player, humanoid: Humanoid)
	local deaths = getStat(victim, "Deaths")
	if deaths then
		deaths.Value += 1
	end

	-- Who landed the last hit in the last few seconds?
	local tag = humanoid:FindFirstChild("creator")
	local killer: Player? = nil
	local weapon = ""
	if tag and tag:IsA("ObjectValue") and tag.Value and tag.Value:IsA("Player") then
		killer = tag.Value
		local weaponAttr = tag:GetAttribute("Weapon")
		weapon = if type(weaponAttr) == "string" then weaponAttr else ""
	end

	-- A killer who left, or a player who tagged themselves, does not get the kill
	if killer and (killer == victim or killer.Parent ~= Players) then
		killer = nil
	end

	if killer then
		local kills = getStat(killer, "Kills")
		if kills then
			kills.Value += 1
		end
		local awardXp = ServerStorage:FindFirstChild("AwardXp")
		if XP_PER_KILL > 0 and awardXp and awardXp:IsA("BindableEvent") then
			awardXp:Fire(killer, XP_PER_KILL)
		end
		killFeed:FireAllClients(killer.DisplayName, victim.DisplayName, weapon)
	elseif SHOW_PLAIN_DEATHS then
		killFeed:FireAllClients("", victim.DisplayName, "")
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats: Instance
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		leaderstats = existing
	else
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	for _, name in { "Kills", "Deaths" } do
		local stat = Instance.new("IntValue")
		stat.Name = name
		stat.Parent = leaderstats
	end

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				onDied(player, humanoid)
			end)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
