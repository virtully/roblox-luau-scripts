--!strict
-- How to make a low gravity zone in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-low-gravity-zone
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named LowGravityZones
-- Script in ServerScriptService named LowGravityZones.
-- Inside a part tagged LowGravityZone, players feel the part's Gravity attribute instead of normal gravity.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEFAULT_ZONE_GRAVITY = 50 -- used when a zone part has no Gravity attribute
local FORCE_NAME = "LowGravityForce"

local function isInside(zone: BasePart, position: Vector3): boolean
	-- In the zone's own space, the point is inside when every axis is within half the size
	local offset = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

-- The gravity of the zone the position is in, or nil when it is in no zone
local function getZoneGravity(position: Vector3): number?
	for _, zone in CollectionService:GetTagged("LowGravityZone") do
		if zone:IsA("BasePart") and isInside(zone, position) then
			local gravity = zone:GetAttribute("Gravity")
			return if typeof(gravity) == "number" then math.max(0, gravity) else DEFAULT_ZONE_GRAVITY
		end
	end
	return nil
end

local function getForce(root: BasePart): VectorForce?
	local existing = root:FindFirstChild(FORCE_NAME)
	if existing and existing:IsA("VectorForce") then
		return existing
	end
	local attachment = root:FindFirstChild("RootAttachment")
	if not (attachment and attachment:IsA("Attachment")) then
		return nil
	end
	local force = Instance.new("VectorForce")
	force.Name = FORCE_NAME
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World -- always straight up
	force.ApplyAtCenterOfMass = true -- push the whole body evenly, so it does not tip over
	force.Parent = root
	return force
end

RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if not (character and humanoid and root) then
			continue
		end
		local zoneGravity = if humanoid.Health > 0 then getZoneGravity(root.Position) else nil
		if zoneGravity then
			local force = getForce(root)
			if force then
				-- Cancel the difference between normal gravity and the zone's gravity.
				-- AssemblyMass is the whole character, and is read every frame because tools change it.
				local lift = root.AssemblyMass * (workspace.Gravity - zoneGravity)
				force.Force = Vector3.new(0, math.max(0, lift), 0)
			end
			if character:GetAttribute("InLowGravity") ~= true then
				character:SetAttribute("InLowGravity", true) -- entered a zone
			end
		else
			local force = root:FindFirstChild(FORCE_NAME)
			if force then
				force:Destroy()
			end
			if character:GetAttribute("InLowGravity") == true then
				character:SetAttribute("InLowGravity", false) -- left the zone
			end
		end
	end
end)
