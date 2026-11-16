--!strict
-- How to make a sports game in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-sports-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named KickClient
-- LocalScript in StarterPlayerScripts named KickClient.
-- Hold F (or the on-screen button, or R2 on a controller) to charge, release to kick.
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FULL_CHARGE = 1 -- seconds of holding for a full-power kick
local kick = ReplicatedStorage:WaitForChild("Kick") :: RemoteEvent
local pressedAt = 0

local function onKick(_action: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		pressedAt = os.clock()
	elseif state == Enum.UserInputState.End then
		local power = math.clamp((os.clock() - pressedAt) / FULL_CHARGE, 0, 1)
		kick:FireServer(power) -- the server checks range and cooldown
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Kick", onKick, true, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("Kick", "Kick")
