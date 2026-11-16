--!strict
-- How to make a cutscene in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-cutscene-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CutscenePlayer
-- LocalScript in StarterPlayer > StarterPlayerScripts named CutscenePlayer.
-- Plays a cutscene the server sends: black bars, captions, a Skip button, and the
-- camera gliding from shot to shot. Then it hands the camera back to the player.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local cutsceneEvent = ReplicatedStorage:WaitForChild("CutsceneEvent") :: RemoteEvent
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BAR_HEIGHT = 0.12 -- each black bar, as a share of the screen height
local EASING_STYLE = Enum.EasingStyle.Sine
local FOCUS_DISTANCE = 30 -- studs in front of the camera that Roblox should render in most detail
local HIDDEN_CORE_GUIS = { Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health }
local REGULAR = Font.fromEnum(Enum.Font.BuilderSans)
local BOLD = Font.fromEnum(Enum.Font.BuilderSansBold)

type Shot = { cframe: CFrame, move: number, hold: number, caption: string }

-- The cutscene screen: two black bars and a caption, edge to edge. Roblox says to use
-- ScreenInsets None only for things nobody presses, so Skip gets its own ScreenGui below.
local gui = Instance.new("ScreenGui")
gui.Name = "Cutscene"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.None -- cover the whole screen
gui.DisplayOrder = 10
gui.Enabled = false

local topBar = Instance.new("Frame")
topBar.Size = UDim2.fromScale(1, BAR_HEIGHT)
topBar.BackgroundColor3 = Color3.new(0, 0, 0)
topBar.BorderSizePixel = 0
topBar.Parent = gui

local bottomBar = topBar:Clone()
bottomBar.Position = UDim2.fromScale(0, 1 - BAR_HEIGHT)
bottomBar.Parent = gui

local caption = Instance.new("TextLabel")
caption.Size = UDim2.fromScale(0.7, 0.5)
caption.Position = UDim2.fromScale(0.15, 0.25)
caption.BackgroundTransparency = 1
caption.TextColor3 = Color3.new(1, 1, 1)
caption.TextScaled = true
caption.FontFace = REGULAR
caption.Text = ""
caption.Parent = bottomBar

-- The Skip button keeps the default insets, so it stays clear of camera notches
local controls = Instance.new("ScreenGui")
controls.Name = "CutsceneControls"
controls.ResetOnSpawn = false
controls.DisplayOrder = 11
controls.Enabled = false

local skipButton = Instance.new("TextButton")
skipButton.AnchorPoint = Vector2.new(1, 0.5)
skipButton.Size = UDim2.fromScale(0.1, BAR_HEIGHT * 0.5)
skipButton.Position = UDim2.new(1, -16, 1 - BAR_HEIGHT / 2, 0) -- on the bottom bar, at the right
skipButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
skipButton.TextColor3 = Color3.new(1, 1, 1)
skipButton.TextScaled = true
skipButton.FontFace = BOLD
skipButton.Text = "Skip"
skipButton.Parent = controls

-- Keep Skip big enough to tap on a small phone screen
local skipMinSize = Instance.new("UISizeConstraint")
skipMinSize.MinSize = Vector2.new(64, 32)
skipMinSize.Parent = skipButton

local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
controls.Parent = playerGui

-- The current move: from one camera CFrame to the next over a number of seconds
local moveFrom = CFrame.identity
local moveTo = CFrame.identity
local moveStart = 0
local moveSeconds = 0
local skipRequested = false
local busy = false

-- Runs every frame during a cutscene. A Scriptable camera's Focus does not follow
-- anything on its own, so it is set here too.
local function updateCamera()
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable -- something reset it, such as a respawn
	end
	local alpha = if moveSeconds > 0 then (os.clock() - moveStart) / moveSeconds else 1
	local eased = TweenService:GetValue(alpha, EASING_STYLE, Enum.EasingDirection.InOut)
	camera.CFrame = moveFrom:Lerp(moveTo, eased)
	camera.Focus = camera.CFrame * CFrame.new(0, 0, -FOCUS_DISTANCE)
end

local function waitOrSkip(seconds: number)
	local endTime = os.clock() + seconds
	while os.clock() < endTime and not skipRequested do
		task.wait()
	end
end

local function play(id: number, shots: { Shot })
	if busy then
		-- Already playing one, so let the server unfreeze the player for this one now
		cutsceneEvent:FireServer(id)
		return
	end
	busy = true
	skipRequested = false

	-- Hide the player list, backpack and health bar, remembering what was shown
	local wasEnabled: { [Enum.CoreGuiType]: boolean } = {}
	for _, coreGui in HIDDEN_CORE_GUIS do
		wasEnabled[coreGui] = StarterGui:GetCoreGuiEnabled(coreGui)
		StarterGui:SetCoreGuiEnabled(coreGui, false)
	end
	-- On phones, hide the thumbstick and jump button, which sit in the bottom corners
	local touchControlsWere = GuiService.TouchControlsEnabled
	GuiService.TouchControlsEnabled = false
	gui.Enabled = true
	controls.Enabled = true
	-- A controller can only press a button that is selected, so select Skip for gamepad players
	if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = skipButton
	end
	camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	moveTo = camera.CFrame
	-- One step after Roblox's own camera update, as Roblox's camera tutorial does
	RunService:BindToRenderStep("Cutscene", Enum.RenderPriority.Camera.Value + 1, updateCamera)

	for _, shot in shots do
		moveFrom = camera.CFrame -- start each move from wherever the camera is now
		moveTo = shot.cframe
		moveStart = os.clock()
		moveSeconds = shot.move
		caption.Text = shot.caption
		waitOrSkip(shot.move + shot.hold)
		if skipRequested then
			break
		end
	end

	-- Hand the camera back to the player's character
	RunService:UnbindFromRenderStep("Cutscene")
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	if GuiService.SelectedObject == skipButton then
		GuiService.SelectedObject = nil
	end
	gui.Enabled = false
	controls.Enabled = false
	caption.Text = ""
	-- Turn back on only the ones this cutscene turned off, and leave the rest alone
	for coreGui, enabled in wasEnabled do
		if enabled then
			StarterGui:SetCoreGuiEnabled(coreGui, true)
		end
	end
	if touchControlsWere then
		GuiService.TouchControlsEnabled = true
	end
	cutsceneEvent:FireServer(id) -- lets the server unfreeze the player now
	busy = false
end

skipButton.Activated:Connect(function()
	skipRequested = true
end)

cutsceneEvent.OnClientEvent:Connect(function(id: number, shots: { Shot })
	play(id, shots)
end)
