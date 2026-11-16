--!strict
-- How to make a trading system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-trading-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named TradeClient
-- LocalScript in StarterPlayerScripts named TradeClient.
-- A Trade button, a list of players to ask, the request popup and the trade window.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tradeEvent = ReplicatedStorage:WaitForChild("Trade") :: RemoteEvent
local player = Players.LocalPlayer

type TradeState = {
	with: string,
	mine: { [string]: number },
	theirs: { [string]: number },
	myReady: boolean,
	theirReady: boolean,
}

local gui = Instance.new("ScreenGui")
gui.Name = "TradeGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function make(className: string, props: { [string]: any }, parent: Instance): any
	local object = Instance.new(className) :: any
	for key, value in props do
		object[key] = value
	end
	if className == "Frame" or className == "TextButton" then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = object
	end
	object.Parent = parent
	return object
end

local DARK = Color3.fromRGB(30, 26, 40)
local WHITE = Color3.new(1, 1, 1)
local function button(text: string, parent: Instance): TextButton
	return make("TextButton", { Text = text, Size = UDim2.fromOffset(110, 36), BackgroundColor3 = Color3.fromRGB(110, 80, 220), TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16 }, parent)
end
local function list(parent: Instance)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end

-- 1. The Trade button and the list of players
local openButton = button("Trade", gui)
openButton.Position = UDim2.new(0, 12, 1, -60)
local playerList = make("Frame", { Position = UDim2.new(0, 12, 1, -110), AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(180, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = DARK, Visible = false }, gui)
list(playerList)

openButton.Activated:Connect(function()
	for _, child in playerList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local b = button(other.DisplayName, playerList)
			b.Size = UDim2.fromOffset(180, 36)
			b.Activated:Connect(function()
				tradeEvent:FireServer("request", other.Name)
				playerList.Visible = false
			end)
		end
	end
	playerList.Visible = not playerList.Visible
end)

-- 2. The popup when someone asks you
local popup = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 80), Size = UDim2.fromOffset(300, 100), BackgroundColor3 = DARK, Visible = false }, gui)
local popupText = make("TextLabel", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 16 }, popup)
local acceptButton = button("Accept", popup)
acceptButton.Position = UDim2.fromOffset(30, 56)
local declineButton = button("Decline", popup)
declineButton.Position = UDim2.fromOffset(160, 56)
local pendingFrom: string? = nil
acceptButton.Activated:Connect(function()
	if pendingFrom then
		tradeEvent:FireServer("accept", pendingFrom)
	end
	popup.Visible = false
end)
declineButton.Activated:Connect(function()
	popup.Visible = false
end)

-- 3. The trade window
local window = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 320), BackgroundColor3 = DARK, Visible = false }, gui)
local title = make("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 18 }, window)
local mineFrame = make("Frame", { Position = UDim2.fromOffset(12, 40), Size = UDim2.fromOffset(240, 220), BackgroundTransparency = 1 }, window)
list(mineFrame)
local theirsText = make("TextLabel", { Position = UDim2.fromOffset(264, 40), Size = UDim2.fromOffset(184, 220), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, window)
local readyButton = button("Ready", window)
readyButton.Position = UDim2.new(0, 12, 1, -48)
local cancelButton = button("Cancel", window)
cancelButton.Position = UDim2.new(1, -122, 1, -48)
readyButton.Activated:Connect(function()
	tradeEvent:FireServer("ready")
end)
cancelButton.Activated:Connect(function()
	tradeEvent:FireServer("cancel")
end)

local function drawTrade(state: TradeState)
	window.Visible = true
	title.Text = "Trading with " .. state.with
	for _, child in mineFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local items = player:FindFirstChild("Items")
	local owned: { Instance } = if items then items:GetChildren() else {}
	for _, item in owned do
		if item:IsA("IntValue") and item.Value > 0 then
			local offered = state.mine[item.Name] or 0
			local row = make("Frame", { Size = UDim2.fromOffset(240, 32), BackgroundTransparency = 1 }, mineFrame)
			make("TextLabel", { Size = UDim2.fromOffset(150, 32), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = string.format("%s  %d / %d", item.Name, offered, item.Value) }, row)
			local minus = button("-", row)
			minus.Size = UDim2.fromOffset(36, 30)
			minus.Position = UDim2.fromOffset(156, 1)
			local plus = button("+", row)
			plus.Size = UDim2.fromOffset(36, 30)
			plus.Position = UDim2.fromOffset(198, 1)
			minus.Activated:Connect(function()
				tradeEvent:FireServer("offer", item.Name, offered - 1)
			end)
			plus.Activated:Connect(function()
				tradeEvent:FireServer("offer", item.Name, offered + 1)
			end)
		end
	end
	local lines = { state.with .. " offers:" }
	for itemName, count in state.theirs do
		table.insert(lines, string.format("%d x %s", count, itemName))
	end
	if #lines == 1 then
		table.insert(lines, "nothing yet")
	end
	table.insert(lines, "")
	table.insert(lines, if state.theirReady then "They are READY" else "They are not ready")
	theirsText.Text = table.concat(lines, "\n")
	readyButton.Text = if state.myReady then "Waiting..." else "Ready"
end

local function message(text: string)
	title.Text = text
	task.delay(2, function()
		if title.Text == text then
			window.Visible = false
		end
	end)
end

tradeEvent.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "requested" then
		pendingFrom = data
		popupText.Text = tostring(data) .. " wants to trade"
		popup.Visible = true
	elseif kind == "update" then
		drawTrade(data :: TradeState)
	elseif kind == "closed" then
		message(tostring(data))
	end
end)
