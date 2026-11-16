--!strict
-- How to make a quest system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-quest-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Quests
-- Script in ServerScriptService named Quests.
-- Tracks each player's quest, counts tagged items and enemies, pays rewards and saves progress.
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

type Quest = {
	title: string,
	kind: "Collect" | "Defeat",
	target: string,
	amount: number,
	reward: number,
}

local quests = require(ReplicatedStorage:WaitForChild("QuestConfig")) :: { Quest }

local ITEM_RESPAWN_SECONDS = 8
local STORE_NAME = "PlayerQuests_v1"

local questCompleted = Instance.new("RemoteEvent")
questCompleted.Name = "QuestCompleted"
questCompleted.Parent = ReplicatedStorage

local loaded: { [Player]: boolean } = {}

local function store(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function giveCoins(player: Player, amount: number)
	-- Use the rebirth system's AwardCoins if it exists, so its multiplier applies
	local awardCoins = ServerStorage:FindFirstChild("AwardCoins")
	if awardCoins and awardCoins:IsA("BindableEvent") then
		awardCoins:Fire(player, amount)
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
	end
end

local function currentQuest(player: Player): Quest?
	local index = player:GetAttribute("QuestIndex")
	if type(index) == "number" then
		return quests[index]
	end
	return nil
end

-- Called by the server only, when it has seen the player do something
local function addProgress(player: Player, kind: string, target: string)
	local quest = currentQuest(player)
	if not quest or quest.kind ~= kind or quest.target ~= target then
		return
	end
	local progress = (tonumber(player:GetAttribute("QuestProgress")) or 0) + 1
	if progress < quest.amount then
		player:SetAttribute("QuestProgress", progress)
		return
	end
	-- Quest done: pay, tell the player, move to the next one
	giveCoins(player, quest.reward)
	questCompleted:FireClient(player, quest.title, quest.reward)
	local index = player:GetAttribute("QuestIndex") :: number
	player:SetAttribute("QuestIndex", index + 1)
	player:SetAttribute("QuestProgress", 0)
end

local function playerFromPart(hit: BasePart): Player?
	local character = hit.Parent
	if character and character:IsA("Model") then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

-- Collect quests: parts tagged QuestItem with an ItemName attribute
local function setUpItem(item: Instance)
	if not item:IsA("BasePart") then
		return
	end
	local ready = true
	item.Touched:Connect(function(hit: BasePart)
		local player = playerFromPart(hit)
		local itemName = item:GetAttribute("ItemName")
		if not (ready and player and type(itemName) == "string") then
			return
		end
		-- Only players who need this item pick it up
		local quest = currentQuest(player)
		if not quest or quest.kind ~= "Collect" or quest.target ~= itemName then
			return
		end
		ready = false
		item.Transparency = 1
		addProgress(player, "Collect", itemName)
		task.delay(ITEM_RESPAWN_SECONDS, function()
			item.Transparency = 0
			ready = true
		end)
	end)
end

-- Defeat quests: Models tagged QuestEnemy with an EnemyName attribute and a Humanoid.
-- The player who landed the killing hit is in an ObjectValue named "creator" in the Humanoid.
local function setUpEnemy(enemy: Instance)
	if not enemy:IsA("Model") then
		return
	end
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local enemyName = enemy:GetAttribute("EnemyName")
		local tag = humanoid:FindFirstChild("creator")
		if type(enemyName) == "string" and tag and tag:IsA("ObjectValue") and tag.Value and tag.Value:IsA("Player") then
			addProgress(tag.Value, "Defeat", enemyName)
		end
	end)
end

for _, item in CollectionService:GetTagged("QuestItem") do
	setUpItem(item)
end
CollectionService:GetInstanceAddedSignal("QuestItem"):Connect(setUpItem)

for _, enemy in CollectionService:GetTagged("QuestEnemy") do
	setUpEnemy(enemy)
end
CollectionService:GetInstanceAddedSignal("QuestEnemy"):Connect(setUpEnemy)

local function onPlayerAdded(player: Player)
	local index, progress = 1, 0
	local ok, data = pcall(function()
		return store():GetAsync(keyFor(player))
	end)
	if ok then
		if type(data) == "table" then
			index = math.max(1, math.floor(tonumber(data.Index) or 1))
			progress = math.max(0, math.floor(tonumber(data.Progress) or 0))
		end
		loaded[player] = true
	else
		warn("Could not load quests for " .. player.Name .. ": " .. tostring(data))
	end
	player:SetAttribute("QuestIndex", index)
	player:SetAttribute("QuestProgress", progress)
end

local function save(player: Player)
	if not loaded[player] then
		return
	end
	local data = {
		Index = player:GetAttribute("QuestIndex"),
		Progress = player:GetAttribute("QuestProgress"),
	}
	local ok, err = pcall(function()
		store():SetAsync(keyFor(player), data, { player.UserId })
	end)
	if not ok then
		warn("Could not save quests for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	save(player)
	loaded[player] = nil
end)

game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
