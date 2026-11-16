--!strict
-- How to make a gun in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gun-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the Blaster Tool in StarterPack named GunClient
-- LocalScript inside the Blaster Tool, named GunClient.
-- Works out where the player is aiming (mouse, tap or the screen centre on a gamepad),
-- sends that point to the server, and shows the ammo while the gun is held.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local tool = script.Parent :: Tool
local fireEvent = ReplicatedStorage:WaitForChild("GunFire") :: RemoteEvent
local reloadEvent = ReplicatedStorage:WaitForChild("GunReload") :: RemoteEvent

local FIRE_INTERVAL = 0.25 -- the same value as in GunService
local MAGAZINE_SIZE = 12 -- the same value as in GunService
local AIM_DISTANCE = 1000

local player = Players.LocalPlayer
local lastShot = 0
local lastTouch: Vector2? = nil

-- Phones have no mouse, so remember where the last tap on the 3D world was
UserInputService.TouchStarted:Connect(function(touch: InputObject, processedByUI: boolean)
	if not processedByUI then
		lastTouch = Vector2.new(touch.Position.X, touch.Position.Y)
	end
end)

local function getAimPoint(): Vector3
	local camera = workspace.CurrentCamera
	local ray: Ray
	local input = UserInputService.PreferredInput
	if input == Enum.PreferredInput.Touch and lastTouch then
		ray = camera:ScreenPointToRay(lastTouch.X, lastTouch.Y) -- a touch Position is measured below the top bar, as this expects
	elseif input == Enum.PreferredInput.KeyboardAndMouse then
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	else -- a gamepad, or a phone before its first tap: the centre of the screen
		local size = camera.ViewportSize
		ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
	end
	local params = RaycastParams.new()
	params.ExcludeInstances = { player.Character :: Model }
	local result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	return if result then result.Position else ray.Origin + ray.Direction * AIM_DISTANCE
end

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastShot < FIRE_INTERVAL then
		return
	end
	lastShot = now
	if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		task.wait() -- wait one frame so TouchStarted has recorded this tap, whichever event fires first
	end
	fireEvent:FireServer(getAimPoint())
end)

-- R on a keyboard, X on a gamepad, and an on-screen button on touch devices
local function onReloadAction(_actionName: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		reloadEvent:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

-- A small ammo label, shown only while the gun is out
local ammoGui = Instance.new("ScreenGui")
ammoGui.Name = "AmmoGui"
-- ResetOnSpawn stays at its default (true): this label belongs to one life of the character
local ammoLabel = Instance.new("TextLabel")
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -24, 1, -24)
ammoLabel.Size = UDim2.fromOffset(140, 44)
ammoLabel.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
ammoLabel.BackgroundTransparency = 0.25
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
ammoLabel.TextSize = 24
ammoLabel.Parent = ammoGui

local function updateAmmo()
	local ammo = tool:GetAttribute("Ammo")
	if tool:GetAttribute("Reloading") == true then
		ammoLabel.Text = "Reloading..."
	else
		ammoLabel.Text = `{if type(ammo) == "number" then ammo else MAGAZINE_SIZE} / {MAGAZINE_SIZE}`
	end
end
tool:GetAttributeChangedSignal("Ammo"):Connect(updateAmmo)
tool:GetAttributeChangedSignal("Reloading"):Connect(updateAmmo)

local isOut = false -- true while this blaster is equipped
local diedConnection: RBXScriptConnection? = nil

local function putAway()
	if not isOut then
		return -- already put away, so the Reload action may now belong to another blaster
	end
	isOut = false
	ammoGui.Parent = nil
	ContextActionService:UnbindAction("ReloadGun")
	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end
end

tool.Equipped:Connect(function()
	isOut = true
	updateAmmo()
	ammoGui.Parent = player:WaitForChild("PlayerGui")
	ContextActionService:BindAction("ReloadGun", onReloadAction, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("ReloadGun", "Reload") -- the text on the touch button
	-- Unequipped may not fire if the holder dies with the blaster out, so hide the label on Died too
	local humanoid = tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid and not diedConnection then
		diedConnection = humanoid.Died:Connect(putAway)
	end
end)

tool.Unequipped:Connect(putAway)

-- Also tidy up if the blaster leaves the game while it is out, for example with a character removed without dying
tool.AncestryChanged:Connect(function()
	if not tool:IsDescendantOf(game) then
		putAway()
	end
end)
