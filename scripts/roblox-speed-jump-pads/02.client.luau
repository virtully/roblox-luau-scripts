--!strict
-- How to make speed pads and jump pads in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-speed-jump-pads
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named JumpPads
-- LocalScript in StarterPlayerScripts named JumpPads.
-- Parts tagged "JumpPad" launch the player upward. A "Power" attribute on a pad
-- overrides the default launch speed.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local LAUNCH_SPEED = 120 -- studs per second straight up
local COOLDOWN = 0.5 -- seconds before the same player can be launched again

local player = Players.LocalPlayer
local lastLaunch = 0

local function setUpPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	-- Touched fires on this device when this player's own character touches the pad
	pad.Touched:Connect(function(hit: BasePart)
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if not (humanoid and root) or humanoid.Health <= 0 then
			return
		end
		local now = os.clock()
		if now - lastLaunch < COOLDOWN then
			return
		end
		lastLaunch = now
		local power = pad:GetAttribute("Power")
		local speed = if typeof(power) == "number" then power else LAUNCH_SPEED
		local v = root.AssemblyLinearVelocity
		-- Keep the sideways speed, replace the vertical speed
		root.AssemblyLinearVelocity = Vector3.new(v.X, speed, v.Z)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end)
end

for _, pad in CollectionService:GetTagged("JumpPad") do
	setUpPad(pad)
end
CollectionService:GetInstanceAddedSignal("JumpPad"):Connect(setUpPad)
