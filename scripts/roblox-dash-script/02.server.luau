--!strict
-- How to make a dash in Roblox Studio (Q to dash)
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-dash-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DashServer
-- Script in ServerScriptService named DashServer.
-- Shows a short trail behind a player who dashes. Keeps its own cooldown per player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SERVER_COOLDOWN = 1.2 -- a little under the client's 1.5, so network delay never drops a real dash
local TRAIL_SECONDS = 0.5

local remote = Instance.new("RemoteEvent")
remote.Name = "DashEffect"
remote.Parent = ReplicatedStorage

local lastDash: { [Player]: number } = {}

-- Makes (once per character) a trail between two attachments on the root part
local function getTrail(root: BasePart): Trail
	local existing = root:FindFirstChild("DashTrail")
	if existing and existing:IsA("Trail") then
		return existing
	end
	local top = Instance.new("Attachment")
	top.Name = "DashTrailTop"
	top.Position = Vector3.new(0, 1, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "DashTrailBottom"
	bottom.Position = Vector3.new(0, -1, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "DashTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.25
	trail.Color = ColorSequence.new(Color3.fromRGB(140, 200, 255))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Enabled = false
	trail.Parent = root
	return trail
end

remote.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (lastDash[player] or -math.huge) < SERVER_COOLDOWN then
		return -- too soon: ignore it
	end
	lastDash[player] = now

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if not (humanoid and root) or humanoid.Health <= 0 then
		return
	end
	local trail = getTrail(root)
	trail.Enabled = true
	task.delay(TRAIL_SECONDS, function()
		if trail.Parent then
			trail.Enabled = false
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastDash[player] = nil
end)
