--!strict
-- How to use a debounce in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-debounce
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named DashServer
-- Script in ServerScriptService named DashServer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

type CooldownModule = {
	try: (Player, string, number) -> boolean,
	remaining: (Player, string, number) -> number,
}
local Cooldown = require(ServerScriptService:WaitForChild("Cooldown")) :: CooldownModule

local DASH_COOLDOWN = 2
local dashRemote = ReplicatedStorage:WaitForChild("Dash") :: RemoteEvent

dashRemote.OnServerEvent:Connect(function(player: Player)
	if not Cooldown.try(player, "Dash", DASH_COOLDOWN) then
		return -- too soon: ignore silently
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity += root.CFrame.LookVector * 60
	end
end)
