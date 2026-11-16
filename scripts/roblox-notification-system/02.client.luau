--!strict
-- How to make a notification system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-notification-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named NotificationClient
-- LocalScript in StarterPlayerScripts named NotificationClient.
-- Shows each notice from the server as a toast in the top right, with a queue.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DURATION = 4 -- seconds each toast stays
local MAX_VISIBLE = 4 -- toasts on screen at once; the rest wait in a queue
local TOAST_WIDTH = 300
local TOAST_HEIGHT = 56

local COLORS: { [string]: Color3 } = {
	info = Color3.fromRGB(90, 150, 255),
	success = Color3.fromRGB(70, 205, 125),
	error = Color3.fromRGB(240, 85, 85),
}

local notifyEvent = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- One ScreenGui for every toast. ResetOnSpawn false keeps toasts on screen when the player respawns.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Notifications"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 -- above most other GUIs
screenGui.Parent = playerGui

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(1, 0)
holder.Position = UDim2.new(1, -16, 0, 16)
holder.Size = UDim2.new(0, TOAST_WIDTH, 1, -32)
holder.BackgroundTransparency = 1
holder.Parent = screenGui

-- The list layout stacks the toasts under each other and closes gaps when one leaves
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = holder

type Notice = { text: string, kind: string }

local queue: { Notice } = {}
local visible = 0
local counter = 0
local slideInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function show(notice: Notice, onClosed: () -> ())
	visible += 1
	counter += 1

	-- The slot holds the toast's place in the list; the card inside it slides
	local slot = Instance.new("Frame")
	slot.Name = "Toast"
	slot.LayoutOrder = counter
	slot.Size = UDim2.fromOffset(TOAST_WIDTH, TOAST_HEIGHT)
	slot.BackgroundTransparency = 1
	slot.Parent = holder

	local card = Instance.new("TextButton")
	card.AutoButtonColor = false
	card.Size = UDim2.fromScale(1, 1)
	card.Position = UDim2.fromScale(1.2, 0) -- start off screen to the right
	card.BackgroundColor3 = Color3.fromRGB(24, 22, 32)
	card.BackgroundTransparency = 0.1
	card.Text = notice.text
	card.TextColor3 = Color3.new(1, 1, 1)
	card.FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium)
	card.TextSize = 18
	card.TextWrapped = true
	card.TextTruncate = Enum.TextTruncate.AtEnd
	card.TextXAlignment = Enum.TextXAlignment.Left
	card.Parent = slot

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	-- A coloured outline says what kind of notice it is. Border mode outlines the box, not the text.
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = COLORS[notice.kind] or COLORS.info
	stroke.Parent = card

	TweenService:Create(card, slideInfo, { Position = UDim2.fromScale(0, 0) }):Play()

	local closed = false
	local function close()
		if closed then
			return -- clicked and timed out at once: close only once
		end
		closed = true
		local slideOut = TweenService:Create(card, slideInfo, { Position = UDim2.fromScale(1.2, 0) })
		slideOut:Play()
		slideOut.Completed:Wait()
		slot:Destroy()
		visible -= 1
		onClosed()
	end

	card.Activated:Connect(close) -- click or tap to close early
	task.delay(DURATION, close)
end

-- Show queued notices while there is room on screen
local function pump()
	while visible < MAX_VISIBLE and #queue > 0 do
		local notice = table.remove(queue, 1)
		if notice then
			show(notice, pump)
		end
	end
end

notifyEvent.OnClientEvent:Connect(function(text: unknown, kind: unknown)
	if typeof(text) ~= "string" or text == "" then
		return
	end
	local safeKind = if typeof(kind) == "string" and COLORS[kind] then kind else "info"
	table.insert(queue, { text = text, kind = safeKind })
	pump()
end)
