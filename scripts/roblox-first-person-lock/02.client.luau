--!strict
-- How to force first person in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-first-person-lock
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named FirstPersonZones
-- LocalScript in StarterPlayerScripts named FirstPersonZones.
-- Inside any part tagged FirstPersonZone, the camera is locked in first person.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local OUTSIDE_DISTANCE = 12 -- studs the camera zooms out to when leaving a zone

local player = Players.LocalPlayer
local normalMinZoom = player.CameraMinZoomDistance
local inside = false

local function isInside(zone: BasePart, position: Vector3): boolean
	-- The position in the zone's own space is inside when every axis is within half its size
	local offset = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local nowInside = false
	for _, zone in CollectionService:GetTagged("FirstPersonZone") do
		if zone:IsA("BasePart") and isInside(zone, root.Position) then
			nowInside = true
			break
		end
	end
	if nowInside == inside then
		return -- nothing changed this frame
	end
	inside = nowInside
	if inside then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = math.min(OUTSIDE_DISTANCE, player.CameraMaxZoomDistance)
		task.delay(0.1, function()
			if not inside then
				player.CameraMinZoomDistance = normalMinZoom
			end
		end)
	end
end)
