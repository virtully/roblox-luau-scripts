--!strict
-- How to make a spectate system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-spectate-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SpectateFocus
-- Script in ServerScriptService named SpectateFocus.
-- Moves a spectator's ReplicationFocus to the player they watch, so streaming loads that area.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MIN_SECONDS_BETWEEN = 0.2 -- ignore requests faster than this

local spectateTarget = Instance.new("RemoteEvent")
spectateTarget.Name = "SpectateTarget"
spectateTarget.Parent = ReplicatedStorage

local lastRequest: { [Player]: number } = {}

spectateTarget.OnServerEvent:Connect(function(player: Player, target: unknown)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < MIN_SECONDS_BETWEEN then
		return
	end
	lastRequest[player] = now

	-- nil means "stop spectating": back to the default, the player's own character
	if target == nil then
		player.ReplicationFocus = nil
		return
	end
	-- Only accept a real player who is still in the game, never any other Instance
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target.Parent ~= Players or target == player then
		return
	end
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		player.ReplicationFocus = root
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
	-- Anyone watching the leaving player goes back to their own focus
	for _, other in Players:GetPlayers() do
		local focus = other.ReplicationFocus
		if focus and player.Character and focus:IsDescendantOf(player.Character) then
			other.ReplicationFocus = nil
		end
	end
end)
