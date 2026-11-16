--!strict
-- How to make a custom loading screen in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-loading-screen
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in ReplicatedFirst named LoadingScreen
-- LocalScript in ReplicatedFirst named LoadingScreen.
-- Replaces Roblox's default loading screen with your own: a title, a progress bar,
-- a Skip button for slow connections, and a fade out when the game is ready.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local TITLE = "My Game"
local MIN_SECONDS = 2 -- show the screen at least this long, so it never just flashes
local SKIP_AFTER_SECONDS = 8 -- offer a Skip button when loading takes longer than this
local STEPS = 20 -- how many times the bar moves while assets preload

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- The screen is built in code, so it exists before anything else in the game has loaded
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true -- also cover the strip at the top of the screen
gui.DisplayOrder = 100 -- in front of every other ScreenGui
gui.ResetOnSpawn = false

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
background.BorderSizePixel = 0
background.Parent = gui

local title = Instance.new("TextLabel")
title.Text = TITLE
title.Font = Enum.Font.GothamBold
title.TextSize = 42
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.42)
title.Size = UDim2.fromOffset(600, 60)
title.Parent = background

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.54)
barBack.Size = UDim2.fromOffset(320, 10)
barBack.BackgroundColor3 = Color3.fromRGB(60, 52, 84)
barBack.BorderSizePixel = 0
barBack.Parent = background

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(160, 120, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBack

local status = Instance.new("TextLabel")
status.Text = "Loading..."
status.Font = Enum.Font.Gotham
status.TextSize = 18
status.TextColor3 = Color3.fromRGB(200, 190, 230)
status.BackgroundTransparency = 1
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.57)
status.Size = UDim2.fromOffset(320, 24)
status.Parent = background

local skip = Instance.new("TextButton")
skip.Text = "Skip"
skip.Font = Enum.Font.GothamBold
skip.TextSize = 18
skip.TextColor3 = Color3.new(1, 1, 1)
skip.BackgroundColor3 = Color3.fromRGB(60, 52, 84)
skip.AnchorPoint = Vector2.new(0.5, 0)
skip.Position = UDim2.fromScale(0.5, 0.64)
skip.Size = UDim2.fromOffset(120, 36)
skip.Visible = false
skip.Parent = background

gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

local started = os.clock()
local skipped = false
skip.Activated:Connect(function()
	skipped = true
end)
task.delay(SKIP_AFTER_SECONDS, function()
	skip.Visible = true
end)

-- Wait until the first copy of the game has arrived from the server
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Preload the images, meshes and sounds in Workspace in STEPS batches, moving the bar after each
local items = workspace:GetDescendants()
local perStep = math.max(1, math.ceil(#items / STEPS))
for first = 1, #items, perStep do
	if skipped then
		break
	end
	ContentProvider:PreloadAsync(table.move(items, first, math.min(first + perStep - 1, #items), 1, {}))
	local done = math.min(first + perStep - 1, #items) / #items
	barFill.Size = UDim2.fromScale(done, 1)
	status.Text = string.format("Loading %d%%", math.floor(done * 100))
end

local shownFor = os.clock() - started
if shownFor < MIN_SECONDS and not skipped then
	task.wait(MIN_SECONDS - shownFor)
end

-- Fade everything out, then remove the screen
local fade = TweenInfo.new(0.5)
for _, object in gui:GetDescendants() do
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		TweenService:Create(object, fade, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif object:IsA("Frame") then
		TweenService:Create(object, fade, { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.5)
gui:Destroy()
