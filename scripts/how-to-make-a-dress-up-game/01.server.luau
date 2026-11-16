--!strict
-- How to make a dress up game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-dress-up-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Fashion
-- Script in ServerScriptService named Fashion.
-- Puts wardrobe items on characters and counts star votes on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local wardrobe = ServerStorage:WaitForChild("Wardrobe")
local wearEvent = ReplicatedStorage:WaitForChild("Wear") :: RemoteEvent
local voteEvent = ReplicatedStorage:WaitForChild("Vote") :: RemoteEvent

-- what each player wears, by slot
local worn: { [Player]: { [string]: Accessory } } = {}

wearEvent.OnServerEvent:Connect(function(player, itemName)
	if typeof(itemName) ~= "string" then
		return
	end
	local item = wardrobe:FindFirstChild(itemName)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not item or not item:IsA("Accessory") or not humanoid then
		return -- not a wardrobe item, or no character yet
	end
	local slot = item:GetAttribute("Slot")
	if typeof(slot) ~= "string" then
		return
	end
	local mine = worn[player] or {}
	worn[player] = mine
	local old = mine[slot]
	if old then
		old:Destroy() -- one item per slot
	end
	local copy = item:Clone()
	humanoid:AddAccessory(copy)
	mine[slot] = copy
end)

-- votes[target][voter] = stars, for the current round only
local votes: { [Player]: { [Player]: number } } = {}
local votingOpen = false

voteEvent.OnServerEvent:Connect(function(voter, target, stars)
	if not votingOpen then
		return
	end
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == voter then
		return -- only other players
	end
	if typeof(stars) ~= "number" or stars ~= math.floor(stars) or stars < 1 or stars > 5 then
		return -- whole stars from 1 to 5
	end
	local forTarget = votes[target] or {}
	votes[target] = forTarget
	forTarget[voter] = stars -- one vote per voter; a new vote replaces the old
end)

-- Call during the vote phase; returns each player's average stars.
local function runVote(seconds: number): { [Player]: number }
	table.clear(votes)
	votingOpen = true
	task.wait(seconds)
	votingOpen = false
	local averages: { [Player]: number } = {}
	for _, player in Players:GetPlayers() do
		local total, count = 0, 0
		local received: { [Player]: number } = votes[player] or {}
		for _, stars in received do
			total += stars
			count += 1
		end
		averages[player] = if count > 0 then total / count else 0
	end
	return averages
end

Players.PlayerRemoving:Connect(function(player)
	worn[player] = nil
	votes[player] = nil
end)

-- one quick test round of voting
task.wait(10)
local results = runVote(20)
for player, average in results do
	print(player.Name, string.format("%.1f stars", average))
end
