--!strict
-- How to make a low gravity zone in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-low-gravity-zone
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ClientLowGravity
-- LocalScript in StarterPlayerScripts named ClientLowGravity.
-- Changes gravity on this player's device only, while they are inside a LowGravityZone part.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEFAULT_ZONE_GRAVITY = 50

local player = Players.LocalPlayer
local normalGravity = workspace.Gravity

local function isInside(zone: BasePart, position: Vector3): boolean
	local offset = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = normalGravity
	if root and root:IsA("BasePart") then
		for _, zone in CollectionService:GetTagged("LowGravityZone") do
			if zone:IsA("BasePart") and isInside(zone, root.Position) then
				local gravity = zone:GetAttribute("Gravity")
				target = if typeof(gravity) == "number" then gravity else DEFAULT_ZONE_GRAVITY
				break
			end
		end
	end
	if workspace.Gravity ~= target then
		workspace.Gravity = target
	end
end)
