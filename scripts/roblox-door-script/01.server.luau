--!strict
-- How to make a door in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-door-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DoorService
-- Script in ServerScriptService named DoorService.
-- Opens and closes every Part or Model tagged "Door" with a hold-E prompt.
-- The server moves the door, so every player sees the same door, and the server
-- checks the distance and the key, so nobody can open a locked door from afar.
--
-- Optional attributes on each door (set them in the Properties window):
--   Style            string  "Swing" (default) or "Slide"
--   OpenAngle        number  degrees a swinging door turns around its pivot (default 90, -179 to 179)
--   SlideDistance    number  studs a sliding door moves along its width (default: its width)
--   OpenSeconds      number  how long opening takes (default 0.6)
--   AutoCloseSeconds number  close again after this long; 0 keeps it open (default 4)
--   KeyName          string  the name of a Tool the player must have, such as "RedKey"

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local DOOR_TAG = "Door"
local PROMPT_DISTANCE = 8 -- studs
local MIN_SECONDS_BETWEEN_USES = 0.3 -- per door, against prompt spam

local doorsSetUp: { [Instance]: boolean } = {}

local function attribute(door: Instance, name: string, default: any): any
	local value = door:GetAttribute(name)
	if value == nil or typeof(value) ~= typeof(default) then
		return default
	end
	if typeof(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
		return default -- NaN or infinity typed into the Properties window
	end
	return value
end

local function hasKey(player: Player, keyName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local inBackpack = backpack and backpack:FindFirstChild(keyName)
	local held = character and character:FindFirstChild(keyName)
	return (inBackpack ~= nil and inBackpack:IsA("Tool")) or (held ~= nil and held:IsA("Tool"))
end

local function setUpDoor(door: Instance)
	if doorsSetUp[door] or not (door:IsA("BasePart") or door:IsA("Model")) then
		return -- already a working door, or not a part or a model
	end
	local promptPart = if door:IsA("Model") then (door.PrimaryPart or door:FindFirstChildWhichIsA("BasePart", true)) else door
	if not (promptPart and promptPart:IsA("BasePart")) then
		warn(`DoorService: {door:GetFullName()} has no part to put the prompt on`)
		return
	end

	doorsSetUp[door] = true
	door.Destroying:Connect(function()
		doorsSetUp[door] = nil
	end)
	-- A copy of a working door brings the old prompt and value with it: remove them
	for _, leftover in door:GetDescendants() do
		if leftover.Name == "DoorPrompt" or leftover.Name == "DoorProgress" then
			leftover:Destroy()
		end
	end

	-- Work out the closed and open positions once, from where the door is placed now
	local closedPivot = door:GetPivot()
	local openPivot: CFrame
	if attribute(door, "Style", "Swing") == "Slide" then
		-- Slide along the door's longer flat side, its width. A Model is measured along its
		-- pivot's sides, a Part by its own Size, so keep a sliding Part's pivot unrotated
		local size = if door:IsA("Model") then door:GetExtentsSize() else (door :: BasePart).Size
		local alongX = size.X >= size.Z
		local width = if alongX then size.X else size.Z
		local direction = if alongX then Vector3.xAxis else Vector3.zAxis
		openPivot = closedPivot * CFrame.new(direction * attribute(door, "SlideDistance", width))
	else
		-- Lerp always turns the shorter way round, so a bigger angle would swing the wrong way
		local angle = math.clamp(attribute(door, "OpenAngle", 90), -179, 179)
		openPivot = closedPivot * CFrame.Angles(0, math.rad(angle), 0)
	end
	local openSeconds = math.clamp(attribute(door, "OpenSeconds", 0.6), 0.05, 10)
	local autoClose = math.max(attribute(door, "AutoCloseSeconds", 4), 0)
	local keyName = attribute(door, "KeyName", "")

	-- Tween a number from 0 (closed) to 1 (open) and move the door to match it.
	-- PivotTo moves a single part or a whole model around its pivot.
	local progress = Instance.new("NumberValue")
	progress.Name = "DoorProgress"
	progress.Parent = door
	progress.Changed:Connect(function(alpha: number)
		door:PivotTo(closedPivot:Lerp(openPivot, alpha))
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DoorPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = if keyName ~= "" then `Needs {keyName}` else "Door"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	local isOpen = false
	local lastUse = 0
	local moveCount = 0

	local function move(open: boolean)
		isOpen = open
		moveCount += 1
		door:SetAttribute("Open", open) -- other scripts can read this
		prompt.ActionText = if open then "Close" else "Open"
		-- A new tween on the same value cancels the old one, so a door can turn back halfway.
		-- Scale the time by how far it still has to go.
		local target = if open then 1 else 0
		local seconds = openSeconds * math.abs(target - progress.Value)
		TweenService:Create(progress, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()

		if open and autoClose > 0 then
			local thisMove = moveCount
			task.delay(openSeconds + autoClose, function()
				if moveCount == thisMove and isOpen then
					move(false)
				end
			end)
		end
	end

	-- Every way of using the door calls this, so they all get the same checks
	local function tryUse(player: Player)
		local now = os.clock()
		if now - lastUse < MIN_SECONDS_BETWEEN_USES then
			return
		end
		-- Roblox's security guide says prompts can be abused like remotes, so check again here
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = humanoid and humanoid.RootPart
		if not (humanoid and rootPart) or humanoid.Health <= 0 then
			return
		end
		if (rootPart.Position - promptPart.Position).Magnitude > PROMPT_DISTANCE + 6 then
			return -- too far away to have used the prompt honestly
		end
		if keyName ~= "" and not isOpen and not hasKey(player, keyName) then
			return -- locked, and this player has no key
		end
		lastUse = now
		move(not isOpen)
	end
	prompt.Triggered:Connect(tryUse)
end

-- Every door tagged now, and any tagged later (including doors cloned in by scripts)
for _, door in CollectionService:GetTagged(DOOR_TAG) do
	setUpDoor(door)
end
CollectionService:GetInstanceAddedSignal(DOOR_TAG):Connect(setUpDoor)
