--!strict
-- How to make an overhead name tag in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-overhead-name-tag
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named NameTags
-- Script in ServerScriptService named NameTags.
-- A name and an optional title above every player's head.
local Players = game:GetService("Players")

local MAX_DISTANCE = 60 -- studs; tags further away are hidden

type Title = { text: string, color: Color3 }

-- UserId -> title. Decided here on the server, where players cannot change it.
local TITLES: { [number]: Title } = {
	[156] = { text = "Owner", color = Color3.fromRGB(255, 200, 60) },
}

local function makeLabel(name: string, text: string, color: Color3, height: number, y: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, height)
	label.Position = UDim2.fromScale(0, y)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label
end

local function addTag(player: Player, character: Model)
	local head = character:WaitForChild("Head", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not (head and head:IsA("BasePart") and humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Adornee = head
	tag.Size = UDim2.fromScale(5, 1.4)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.MaxDistance = MAX_DISTANCE
	tag.LightInfluence = 0

	local title = TITLES[player.UserId]
	if title then
		makeLabel("Title", title.text, title.color, 0.4, 0).Parent = tag
		makeLabel("PlayerName", player.DisplayName, Color3.new(1, 1, 1), 0.6, 0.4).Parent = tag
	else
		makeLabel("PlayerName", player.DisplayName, Color3.new(1, 1, 1), 0.6, 0.4).Parent = tag
	end
	tag.Parent = head
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		addTag(player, character)
	end)
	if player.Character then
		task.spawn(addTag, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
