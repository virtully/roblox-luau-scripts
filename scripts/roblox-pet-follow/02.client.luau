--!strict
-- How to make a pet that follows you in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-pet-follow
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named PetBob
-- LocalScript in StarterPlayerScripts named PetBob.
-- Makes the local player's pet bob up and down by moving the point it follows.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BOB_HEIGHT = 0.5 -- studs up and down
local BOB_SPEED = 3 -- higher bobs faster (3 is about one bob every 2 seconds)

local player = Players.LocalPlayer
local baseY: number? = nil

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = root and root:FindFirstChild("PetTarget")
	if not (target and target:IsA("Attachment")) then
		baseY = nil
		return
	end
	local y = baseY or target.Position.Y
	baseY = y
	local p = target.Position
	target.Position = Vector3.new(p.X, y + math.sin(os.clock() * BOB_SPEED) * BOB_HEIGHT, p.Z)
end)
