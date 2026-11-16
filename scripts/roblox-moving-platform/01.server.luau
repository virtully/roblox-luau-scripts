--!strict
-- How to make a moving platform in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-moving-platform
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the platform part named MovingPlatform
-- Script inside a platform part, named MovingPlatform.
-- Moves the platform back and forth with physics, so players standing on it ride
-- along. Set a Vector3 attribute "Travel" on the part, e.g. 0, 0, 30 for 30 studs along Z.
local SPEED = 8 -- studs per second
local PAUSE_SECONDS = 2 -- wait at each end

local platform = script.Parent :: BasePart
local travelAttr = platform:GetAttribute("Travel")
local travel = if typeof(travelAttr) == "Vector3" then travelAttr else Vector3.new(0, 0, 30)

local startCFrame = platform.CFrame
local startPosition = startCFrame.Position
local endPosition = startPosition + travel

-- The platform is moved by physics, not by changing its position, so it must not be anchored
platform.Anchored = false

local attachment = Instance.new("Attachment")
attachment.Parent = platform

-- AlignPosition pulls the platform toward a point, at no more than SPEED
local mover = Instance.new("AlignPosition")
mover.Mode = Enum.PositionAlignmentMode.OneAttachment
mover.Attachment0 = attachment
mover.Position = startPosition
mover.MaxVelocity = SPEED
mover.MaxForce = math.huge
mover.Responsiveness = 200
mover.Parent = platform

-- AlignOrientation keeps it flat and stops it from spinning
local holder = Instance.new("AlignOrientation")
holder.Mode = Enum.OrientationAlignmentMode.OneAttachment
holder.Attachment0 = attachment
holder.CFrame = startCFrame.Rotation
holder.MaxTorque = math.huge
holder.Responsiveness = 200
holder.Parent = platform

-- The server always moves it, so it does not stutter when a different player gets near
platform:SetNetworkOwner(nil)

local distance = travel.Magnitude
local target = endPosition
while true do
	mover.Position = target
	-- Wait about as long as the trip takes, then pause
	task.wait(distance / SPEED + PAUSE_SECONDS)
	target = if target == endPosition then startPosition else endPosition
end
