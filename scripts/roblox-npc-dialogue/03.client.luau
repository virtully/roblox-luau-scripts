--!strict
-- How to make NPC dialogue in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-npc-dialogue
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayer > StarterPlayerScripts named DialogueClient
-- LocalScript in StarterPlayer > StarterPlayerScripts named DialogueClient.
-- Draws the conversation the server sends: the NPC's name, its line typed out letter
-- by letter, a speech bubble over its head and one button per choice. Clicking a
-- choice only sends its number; the server decides what happens next.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local dialogueEvent = ReplicatedStorage:WaitForChild("DialogueEvent") :: RemoteEvent
local player = Players.LocalPlayer

local LETTERS_PER_SECOND = 45
local REGULAR = Font.fromEnum(Enum.Font.BuilderSans)
local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)

-- The dialogue box, built in code
local gui = Instance.new("ScreenGui")
gui.Name = "Dialogue"
gui.ResetOnSpawn = false
gui.Enabled = false

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 1)
box.Position = UDim2.new(0.5, 0, 1, -84) -- 84 pixels up, so Roblox's tool bar never covers the choices
box.Size = UDim2.fromScale(0.6, 0.34)
box.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
box.BackgroundTransparency = 0.1
box.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = box
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(720, 300)
sizeLimit.Parent = box

local nameLabel = Instance.new("TextLabel")
nameLabel.Position = UDim2.fromScale(0.04, 0.04)
nameLabel.Size = UDim2.fromScale(0.8, 0.14)
nameLabel.BackgroundTransparency = 1
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextColor3 = Color3.fromRGB(190, 160, 255)
nameLabel.TextScaled = true
nameLabel.FontFace = BOLD
nameLabel.Parent = box

local lineLabel = nameLabel:Clone()
lineLabel.Position = UDim2.fromScale(0.04, 0.2)
lineLabel.Size = UDim2.fromScale(0.92, 0.3)
lineLabel.TextColor3 = Color3.new(1, 1, 1)
lineLabel.TextScaled = true -- a long line shrinks to fit on a small phone screen
lineLabel.TextWrapped = true
lineLabel.TextYAlignment = Enum.TextYAlignment.Top
lineLabel.FontFace = REGULAR
lineLabel.Parent = box
local lineTextLimit = Instance.new("UITextSizeConstraint")
lineTextLimit.MaxTextSize = 20 -- and never grows past 20 pixels on a big one
lineTextLimit.Parent = lineLabel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 8)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.BackgroundTransparency = 1
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 20
closeButton.FontFace = BOLD
closeButton.Parent = box

local choiceList = Instance.new("Frame")
choiceList.Position = UDim2.fromScale(0.04, 0.52)
choiceList.Size = UDim2.fromScale(0.92, 0.44)
choiceList.BackgroundTransparency = 1
choiceList.Parent = box
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.5, -6, 0.5, -6)
layout.CellPadding = UDim2.fromOffset(6, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = choiceList

gui.Parent = player:WaitForChild("PlayerGui")

local talkingTo: Model? = nil
local lineNumber = 0 -- goes up with every new line, so an old typing loop stops

local function setPromptVisible(npc: Model?, visible: boolean)
	local root = npc and npc:FindFirstChild("HumanoidRootPart")
	local prompt = root and root:FindFirstChild("TalkPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = visible -- changed on this device only
	end
end

local function clearChoices()
	for _, child in choiceList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function close()
	lineNumber += 1
	clearChoices()
	gui.Enabled = false
	setPromptVisible(talkingTo, true)
	talkingTo = nil
	GuiService.SelectedObject = nil
end

local function show(npc: Model, text: string, choices: { string })
	lineNumber += 1
	local thisLine = lineNumber
	if talkingTo ~= npc then
		setPromptVisible(talkingTo, true)
		talkingTo = npc
		setPromptVisible(npc, false)
	end
	gui.Enabled = true
	nameLabel.Text = npc.Name
	clearChoices()

	-- A speech bubble over the NPC (DisplayBubble only works in a LocalScript)
	local head = npc:FindFirstChild("Head")
	if head then
		TextChatService:DisplayBubble(head, text)
	end

	-- Type the line out, letter by letter. The count comes from the time passed,
	-- so the speed is the same at any frame rate.
	lineLabel.Text = text
	lineLabel.MaxVisibleGraphemes = 0
	local letters = 0
	for _ in utf8.graphemes(text) do
		letters += 1
	end
	local startTime = os.clock()
	local shown = 0
	while shown < letters do
		task.wait()
		if lineNumber ~= thisLine then
			return -- a newer line or a close replaced this one
		end
		shown = math.min(letters, math.floor((os.clock() - startTime) * LETTERS_PER_SECOND))
		lineLabel.MaxVisibleGraphemes = shown
	end
	lineLabel.MaxVisibleGraphemes = -1

	-- One button per choice; the server only ever receives the button's number
	for index, choiceText in choices do
		local button = Instance.new("TextButton")
		button.LayoutOrder = index
		button.BackgroundColor3 = Color3.fromRGB(124, 77, 255)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.FontFace = BOLD
		button.Text = choiceText
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button
		button.Parent = choiceList
		button.Activated:Connect(function()
			if lineNumber == thisLine then
				lineNumber += 1 -- one click per line
				dialogueEvent:FireServer(index)
			end
		end)
		if index == 1 and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
			GuiService.SelectedObject = button -- so a controller can pick a choice
		end
	end
end

closeButton.Activated:Connect(function()
	dialogueEvent:FireServer(0)
	close()
end)

dialogueEvent.OnClientEvent:Connect(function(kind: string, npc: Model?, text: string?, choices: { string }?)
	if kind == "show" and npc and text and choices then
		show(npc, text, choices)
	elseif kind == "close" then
		close()
	end
end)
