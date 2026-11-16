--!strict
-- How to make a main menu in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-main-menu
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MainMenu
-- LocalScript in StarterPlayerScripts named MainMenu.
-- Shows a title and a Play button over a slow camera shot of your map. Play fades
-- to black, asks the server for a character, hands the camera back and fades in.
-- It lives in StarterPlayerScripts because StarterGui is only copied when a character
-- spawns, and in this game nobody has a character until they press Play.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GAME_TITLE = "My Game"
local FADE_SECONDS = 0.6
local SPAWN_TIMEOUT = 15 -- seconds to wait for the server before letting the player try again

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local playRequest = ReplicatedStorage:WaitForChild("PlayRequest") :: RemoteEvent
local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)

-- The menu: a title and a Play button, kept inside the screen's safe area
local gui = Instance.new("ScreenGui")
gui.Name = "MainMenu"
gui.ResetOnSpawn = false -- otherwise Roblox removes it the moment the character spawns
gui.DisplayOrder = 10

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.3)
title.Size = UDim2.fromScale(0.7, 0.14)
title.BackgroundTransparency = 1
title.Text = GAME_TITLE
title.TextColor3 = Color3.new(1, 1, 1)
title.FontFace = BOLD
title.TextScaled = true
title.Parent = gui

local playButton = Instance.new("TextButton")
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.Position = UDim2.fromScale(0.5, 0.62)
playButton.Size = UDim2.fromScale(0.24, 0.1)
playButton.BackgroundColor3 = Color3.fromRGB(124, 77, 255)
playButton.Text = "Play"
playButton.TextColor3 = Color3.new(1, 1, 1)
playButton.FontFace = BOLD
playButton.TextScaled = true
playButton.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = playButton
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(160, 56) -- stays tappable on small phones
sizeLimit.MaxSize = Vector2.new(360, 90)
sizeLimit.Parent = playButton

-- The fade: a black frame in its own ScreenGui. Nothing in it can be pressed, so it may
-- cover the whole screen, top bar area included. It starts black.
local fadeGui = Instance.new("ScreenGui")
fadeGui.Name = "MenuFade"
fadeGui.ResetOnSpawn = false
fadeGui.ScreenInsets = Enum.ScreenInsets.None
fadeGui.DisplayOrder = 11 -- drawn on top of the menu

local fade = Instance.new("Frame")
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 0
fade.Parent = fadeGui

fadeGui.Parent = playerGui
gui.Parent = playerGui

local function tweenFade(transparency: number)
	local tween = TweenService:Create(fade, TweenInfo.new(FADE_SECONDS), { BackgroundTransparency = transparency })
	tween:Play()
	tween.Completed:Wait()
end

-- Hide the player list, backpack and chat while the menu is up
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

-- Camera: aim at a part named MenuCamera if the map has one, and sway slowly
local menuCameraPart = workspace:WaitForChild("MenuCamera", 5) -- may take a moment to stream in
local baseCFrame = if menuCameraPart and menuCameraPart:IsA("BasePart")
	then menuCameraPart.CFrame
	else CFrame.lookAt(Vector3.new(0, 40, 80), Vector3.zero)
local startTime = os.clock()
camera.CameraType = Enum.CameraType.Scriptable
RunService:BindToRenderStep("MenuCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local t = os.clock() - startTime
	-- Turn around the world's up axis, so a camera that looks down keeps the horizon level
	local yaw = math.sin(t * 0.25) * 0.15
	camera.CFrame = CFrame.new(baseCFrame.Position) * CFrame.Angles(0, yaw, 0) * baseCFrame.Rotation
	-- Focus is the point the camera looks at. Roblox's camera scripts stop setting it while
	-- the camera is Scriptable, so set it 40 studs in front of the camera.
	camera.Focus = camera.CFrame * CFrame.new(0, 0, -40)
end)

-- A controller cannot press a button until one is selected, so select Play for gamepad players
local function selectPlayForGamepad()
	if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = playButton
	end
end
local inputChanged = UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(selectPlayForGamepad)

local busy = false
playButton.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	playButton.Text = "Loading..."
	tweenFade(0)
	playRequest:FireServer()

	-- Wait for the server to spawn us
	local deadline = os.clock() + SPAWN_TIMEOUT
	while not player.Character and os.clock() < deadline do
		task.wait(0.1)
	end
	local character = player.Character
	local humanoid = character and character:WaitForChild("Humanoid", 5)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		playButton.Text = "Try again"
		tweenFade(1)
		busy = false
		return
	end

	-- Hand the camera back to Roblox's normal camera, following our character
	RunService:UnbindFromRenderStep("MenuCamera")
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	inputChanged:Disconnect()
	if GuiService.SelectedObject == playButton then
		GuiService.SelectedObject = nil
	end
	gui:Destroy() -- the title and button go while the screen is still black
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	tweenFade(1)
	fadeGui:Destroy()
end)

-- Everything is ready: select Play for a controller and fade in on the menu
selectPlayForGamepad()
tweenFade(1)
