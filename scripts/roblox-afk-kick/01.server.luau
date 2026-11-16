--!strict
-- How to detect and kick AFK players in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-afk-kick
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named AfkManager
-- Script in ServerScriptService named AfkManager.
-- Marks players AFK when their client reports Player.Idled, tags them, moves them and kicks them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KICK_AFTER_SECONDS = 600 -- 0 = never kick. Counted from when Idled fires.
local MOVE_TO_AFK_ZONE = true -- needs a part named AfkZone in Workspace
local SHOW_TAG = true
local MIN_SECONDS_BETWEEN = 1 -- ignore reports faster than this
local KICK_MESSAGE = "You were away for too long. Rejoin any time!"

local afkStatus = Instance.new("RemoteEvent")
afkStatus.Name = "AfkStatus"
afkStatus.Parent = ReplicatedStorage

local afkSince: { [Player]: number } = {}
local returnTo: { [Player]: CFrame } = {}
local lastReport: { [Player]: number } = {}

local function setTag(player: Player, on: boolean)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("AfkTag")
	if existing then
		existing:Destroy()
	end
	if not (on and SHOW_TAG) then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = "AfkTag"
	tag.Size = UDim2.fromOffset(80, 30)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "AFK"
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = tag
	tag.Parent = head
end

local function setAfk(player: Player, afk: boolean)
	if (afkSince[player] ~= nil) == afk then
		return -- no change
	end
	player:SetAttribute("AFK", afk)
	setTag(player, afk)

	local character = player.Character
	local zone = workspace:FindFirstChild("AfkZone")
	if afk then
		afkSince[player] = os.clock()
		if MOVE_TO_AFK_ZONE and character and zone and zone:IsA("BasePart") then
			returnTo[player] = character:GetPivot()
			character:PivotTo(zone.CFrame + Vector3.new(0, zone.Size.Y / 2 + 3, 0))
		end
	else
		afkSince[player] = nil
		local back = returnTo[player]
		returnTo[player] = nil
		if back and character then
			character:PivotTo(back)
		end
	end
end

afkStatus.OnServerEvent:Connect(function(player: Player, afk: unknown)
	if type(afk) ~= "boolean" then
		return
	end
	local now = os.clock()
	if now - (lastReport[player] or 0) < MIN_SECONDS_BETWEEN then
		return
	end
	lastReport[player] = now
	setAfk(player, afk)
end)

-- A new character starts without the tag; put it back if the player is still AFK
local function onPlayerAdded(player: Player)
	player:SetAttribute("AFK", false)
	player.CharacterAdded:Connect(function(character: Model)
		returnTo[player] = nil
		if afkSince[player] then
			character:WaitForChild("Head", 5)
			setTag(player, true)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	afkSince[player] = nil
	returnTo[player] = nil
	lastReport[player] = nil
end)

-- Kick anyone who has been AFK for too long
while true do
	task.wait(10)
	if KICK_AFTER_SECONDS > 0 then
		local now = os.clock()
		for player, since in afkSince do
			if now - since >= KICK_AFTER_SECONDS then
				afkSince[player] = nil
				player:Kick(KICK_MESSAGE)
			end
		end
	end
end
