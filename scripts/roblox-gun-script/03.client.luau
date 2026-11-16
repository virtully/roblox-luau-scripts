--!strict
-- How to make a gun in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gun-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named GunEffects
-- LocalScript in StarterPlayerScripts named GunEffects.
-- Draws every shot the server confirms, for every player, as a short neon beam.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shotEvent = ReplicatedStorage:WaitForChild("GunShot") :: RemoteEvent

local BEAM_SECONDS = 0.08

shotEvent.OnClientEvent:Connect(function(handle: BasePart, hitPosition: Vector3)
	if not handle or not handle.Parent then
		return -- the gun is gone, or has not streamed in on this device
	end
	local origin = handle.Position
	local distance = (hitPosition - origin).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 214, 90)
	beam.Size = Vector3.new(0.12, 0.12, distance)
	beam.CFrame = CFrame.lookAt(origin, hitPosition) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, BEAM_SECONDS)
end)
