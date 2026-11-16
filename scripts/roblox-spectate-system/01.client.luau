--!strict
-- How to make a spectate system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-spectate-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterGui named Spectate
-- LocalScript in StarterGui named Spectate.
-- A Spectate button plus previous and next arrows that point the camera at other living players.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SKIP_AFTER_DEATH = 2 -- seconds to keep watching a player who died
local PREVIOUS_KEY = Enum.KeyCode.Q
local NEXT_KEY = Enum.KeyCode.E

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ---------- The buttons ----------
local gui = Instance.new("ScreenGui")
gui.Name = "SpectateGui"
gui.ResetOnSpawn = false

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -16)
bar.Size = UDim2.fromOffset(340, 44)
bar.BackgroundTransparency = 1
bar.Parent = gui

local function makeButton(text: string, x: number, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(x, 0)
	button.Size = UDim2.fromOffset(width, 44)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Text = text
	button.Parent = bar
	Instance.new("UICorner").Parent = button
	return button
end

local previousButton = makeButton("<", 0, 44)
local toggleButton = makeButton("Spectate", 52, 236)
local nextButton = makeButton(">", 296, 44)
previousButton.Visible = false
nextButton.Visible = false

gui.Parent = player:WaitForChild("PlayerGui")

-- ---------- Spectating ----------
local spectating = false
local target: Player? = nil
local targetConnections: { RBXScriptConnection } = {}

-- Tell the server who we watch, so streaming loads around them (Step 3). Optional.
local focusEvent = ReplicatedStorage:FindFirstChild("SpectateTarget")

local function aliveHumanoid(other: Player): Humanoid?
	local character = other.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- Everyone we could watch: other players who are alive, in join order
local function candidates(): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and aliveHumanoid(other) then
			table.insert(list, other)
		end
	end
	return list
end

local function clearTargetConnections()
	for _, connection in targetConnections do
		connection:Disconnect()
	end
	table.clear(targetConnections)
end

local function watchOwnCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local setTarget: (Player?) -> ()
local step: (number) -> ()

local function pointCamera()
	local humanoid = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

setTarget = function(newTarget: Player?)
	clearTargetConnections()
	target = newTarget
	if focusEvent and focusEvent:IsA("RemoteEvent") then
		focusEvent:FireServer(newTarget)
	end
	if not newTarget then
		toggleButton.Text = if spectating then "Nobody to watch" else "Spectate"
		watchOwnCharacter()
		return
	end
	toggleButton.Text = newTarget.DisplayName
	pointCamera()
	-- They respawned: follow the new character
	table.insert(targetConnections, newTarget.CharacterAdded:Connect(function(character: Model)
		character:WaitForChild("Humanoid", 5)
		if target == newTarget then
			pointCamera()
			-- The old root part is gone, so send the new one to the server for streaming
			if focusEvent and focusEvent:IsA("RemoteEvent") then
				focusEvent:FireServer(newTarget)
			end
		end
	end))
	-- They died: wait a moment, then move on to someone alive
	local humanoid = aliveHumanoid(newTarget)
	if humanoid then
		table.insert(targetConnections, humanoid.Died:Connect(function()
			task.wait(SKIP_AFTER_DEATH)
			if spectating and target == newTarget then
				step(1)
			end
		end))
	end
end

-- Move forward (1) or back (-1) through the list of living players
step = function(direction: number)
	local list = candidates()
	if #list == 0 then
		setTarget(nil)
		return
	end
	local found = if target then table.find(list, target) else nil
	-- Wrap round at the ends; start at the first player if the old target is gone
	local index = if found then (found - 1 + direction) % #list + 1 else 1
	setTarget(list[index])
end

local function setSpectating(on: boolean)
	spectating = on
	previousButton.Visible = on
	nextButton.Visible = on
	if on then
		step(1)
	else
		setTarget(nil)
	end
end

toggleButton.Activated:Connect(function()
	setSpectating(not spectating)
end)
previousButton.Activated:Connect(function()
	step(-1)
end)
nextButton.Activated:Connect(function()
	step(1)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or not spectating then
		return
	end
	if input.KeyCode == PREVIOUS_KEY then
		step(-1)
	elseif input.KeyCode == NEXT_KEY then
		step(1)
	end
end)

-- The watched player left: switch to the next one
Players.PlayerRemoving:Connect(function(leaving: Player)
	if leaving == target then
		target = nil
		if spectating then
			step(1)
		end
	end
end)

-- Our own respawn makes the default camera point at us again, so put it back
player.CharacterAdded:Connect(function()
	if spectating then
		task.wait(0.1)
		pointCamera()
	end
end)
