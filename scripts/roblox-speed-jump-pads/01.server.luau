--!strict
-- How to make speed pads and jump pads in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-speed-jump-pads
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SpeedPads
-- Script in ServerScriptService named SpeedPads.
-- Parts tagged "SpeedPad" raise WalkSpeed for a few seconds. Attributes on a pad
-- (Speed, Seconds) override the defaults below.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local BOOST_SPEED = 40 -- WalkSpeed while boosted (Roblox's default is 16)
local BOOST_SECONDS = 4

local normalSpeed: { [Humanoid]: number } = {} -- the speed to go back to
local boostId: { [Humanoid]: number } = {} -- so only the latest boost ends it

local function setUpPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	pad.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		if not (character and character:IsA("Model") and Players:GetPlayerFromCharacter(character)) then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		local speedAttr = pad:GetAttribute("Speed")
		local secondsAttr = pad:GetAttribute("Seconds")
		local speed = if typeof(speedAttr) == "number" then speedAttr else BOOST_SPEED
		local seconds = if typeof(secondsAttr) == "number" then secondsAttr else BOOST_SECONDS

		if normalSpeed[humanoid] == nil then
			normalSpeed[humanoid] = humanoid.WalkSpeed
			humanoid.Destroying:Connect(function()
				normalSpeed[humanoid] = nil
				boostId[humanoid] = nil
			end)
		end
		local id = (boostId[humanoid] or 0) + 1
		boostId[humanoid] = id
		humanoid.WalkSpeed = speed

		task.delay(seconds, function()
			-- A newer pad touch restarted the boost: let that one end it
			if boostId[humanoid] ~= id then
				return
			end
			local before = normalSpeed[humanoid]
			if before then
				humanoid.WalkSpeed = before
			end
			normalSpeed[humanoid] = nil
		end)
	end)
end

for _, pad in CollectionService:GetTagged("SpeedPad") do
	setUpPad(pad)
end
CollectionService:GetInstanceAddedSignal("SpeedPad"):Connect(setUpPad)
