--!strict
-- How to make NPC dialogue in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-dialogue
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DialogueService
-- Script in ServerScriptService named DialogueService.
-- Adds a Talk prompt to every NPC in Workspace.NPCs and runs each conversation.
-- The player's device only shows the text and sends back the number of the choice
-- they clicked. The server knows which line each player is on, checks the choice
-- and the distance, and is the only side that heals or gives items.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- The same shapes as in DialogueData, so Studio's type checker knows them here too
type Choice = { text: string, next: string?, action: string?, item: string?, failNext: string? }
type Line = { text: string, choices: { Choice } }
local DialogueData = require(ReplicatedStorage:WaitForChild("DialogueData")) :: { [string]: { [string]: Line } }

local TALK_DISTANCE = 12 -- studs: the prompt's range, and how close a player must stay
local MIN_SECONDS_BETWEEN_CHOICES = 0.3
local HEAL_COOLDOWN_SECONDS = 30

local npcFolder = workspace:WaitForChild("NPCs")
local itemFolder = ServerStorage:FindFirstChild("DialogueItems")

-- This script makes DialogueEvent itself, so do not add one by hand
local dialogueEvent = Instance.new("RemoteEvent")
dialogueEvent.Name = "DialogueEvent"
dialogueEvent.Parent = ReplicatedStorage

type Conversation = { npc: Model, npcName: string, lineId: string, lastChoice: number }
local conversations: { [Player]: Conversation } = {}
local lastHeal: { [Player]: number } = {}

local function rootOf(model: Model?): BasePart?
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isClose(player: Player, npc: Model): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local playerRoot = rootOf(character)
	local npcRoot = rootOf(npc)
	if not (humanoid and humanoid.Health > 0 and playerRoot and npcRoot) then
		return false -- no character, a dead one, or the NPC is gone
	end
	-- a little extra room, because the player's position reaches the server slightly late
	return (playerRoot.Position - npcRoot.Position).Magnitude <= TALK_DISTANCE + 4
end

-- What the server does when a choice has an action. Each returns true if it did it.
local ACTIONS: { [string]: (player: Player, choice: Choice) -> boolean } = {
	Heal = function(player)
		local now = os.clock()
		if now - (lastHeal[player] or -math.huge) < HEAL_COOLDOWN_SECONDS then
			return false -- healed too recently
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (humanoid and humanoid.Health > 0) then
			return false
		end
		lastHeal[player] = now
		humanoid.Health = humanoid.MaxHealth
		return true
	end,
	GiveItem = function(player, choice)
		local itemName = choice.item
		local template = itemFolder and itemName and itemFolder:FindFirstChild(itemName)
		if not (itemName and template and template:IsA("Tool")) then
			warn(`DialogueService: no Tool named {itemName} in ServerStorage.DialogueItems`)
			return false
		end
		local backpack = player:FindFirstChildOfClass("Backpack")
		local character = player.Character
		if not backpack or backpack:FindFirstChild(itemName) or (character and character:FindFirstChild(itemName)) then
			return false -- no backpack yet, or they already have one
		end
		local item = template:Clone() :: Tool
		item.CanBeDropped = false -- so nobody can drop it and ask for another
		item.Parent = backpack
		return true
	end,
}

local function showLine(player: Player, conversation: Conversation)
	local line = DialogueData[conversation.npcName][conversation.lineId]
	local choiceTexts = {}
	for _, choice in line.choices do
		table.insert(choiceTexts, choice.text)
	end
	dialogueEvent:FireClient(player, "show", conversation.npc, line.text, choiceTexts)
end

local function endConversation(player: Player)
	if conversations[player] then
		conversations[player] = nil
		dialogueEvent:FireClient(player, "close")
	end
end

local function startConversation(player: Player, npc: Model)
	local npcName = npc.Name
	local lines = DialogueData[npcName]
	if conversations[player] or not (lines and lines.start) or not isClose(player, npc) then
		return -- already talking, no "start" line for this NPC, dead or too far away
	end
	local conversation = { npc = npc, npcName = npcName, lineId = "start", lastChoice = 0 }
	conversations[player] = conversation
	showLine(player, conversation)
end

-- The player clicked choice number choiceIndex (0 means they closed the box)
dialogueEvent.OnServerEvent:Connect(function(player: Player, choiceIndex: unknown)
	local conversation = conversations[player]
	if not conversation then
		return
	end
	if typeof(choiceIndex) ~= "number" or choiceIndex ~= math.floor(choiceIndex) then
		return
	end
	if choiceIndex == 0 or not isClose(player, conversation.npc) then
		endConversation(player)
		return
	end
	local now = os.clock()
	if now - conversation.lastChoice < MIN_SECONDS_BETWEEN_CHOICES then
		-- Too fast. Send the same line again, because the box has already locked its
		-- buttons after the click and would otherwise wait for an answer forever.
		showLine(player, conversation)
		return
	end
	conversation.lastChoice = now

	local line = DialogueData[conversation.npcName][conversation.lineId]
	local choice = line.choices[choiceIndex]
	if not choice then
		return -- there is no such choice on the line this player is reading
	end
	local nextLine = choice.next
	if choice.action then
		local action = ACTIONS[choice.action]
		local done = false
		if action then
			done = action(player, choice)
		else
			warn(`DialogueService: no action named {choice.action}`)
		end
		if not done and choice.failNext then
			nextLine = choice.failNext -- for example "I healed you a moment ago"
		end
	end
	if nextLine and not DialogueData[conversation.npcName][nextLine] then
		warn(`DialogueService: no line named {nextLine} for {conversation.npcName} in DialogueData`)
		nextLine = nil
	end
	if nextLine then
		conversation.lineId = nextLine
		showLine(player, conversation)
	else
		endConversation(player)
	end
end)

-- A Talk prompt on each NPC
local function setUpNpc(npc: Instance)
	local root = if npc:IsA("Model") then rootOf(npc) else nil
	if not (npc:IsA("Model") and root) then
		return
	end
	if not (DialogueData[npc.Name] and DialogueData[npc.Name].start) then
		warn(`DialogueService: no conversation with a start line for {npc.Name} in DialogueData`)
	end
	local leftover = root:FindFirstChild("TalkPrompt")
	if leftover then
		leftover:Destroy() -- a copy of an NPC brings the old prompt, which nothing listens to
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = npc.Name
	prompt.MaxActivationDistance = TALK_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player: Player)
		startConversation(player, npc)
	end)
end

for _, npc in npcFolder:GetChildren() do
	setUpNpc(npc)
end
npcFolder.ChildAdded:Connect(setUpNpc)

-- Close the box for anyone who walks away or dies mid-conversation
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, conversation in conversations do
			if not isClose(player, conversation.npc) then
				endConversation(player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	conversations[player] = nil
	lastHeal[player] = nil
end)
