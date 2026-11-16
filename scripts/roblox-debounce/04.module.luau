--!strict
-- How to use a debounce in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-debounce
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Cooldown
-- ModuleScript in ServerScriptService named Cooldown.
-- Cooldown.try(player, "Dash", 2) returns true at most once every 2 seconds for that player and action.
local Players = game:GetService("Players")

local Cooldown = {}

local lastUse: { [Player]: { [string]: number } } = {}

function Cooldown.try(player: Player, action: string, seconds: number): boolean
	local now = os.clock()
	local actions = lastUse[player]
	if not actions then
		actions = {}
		lastUse[player] = actions
	end
	local last = actions[action]
	if last and now - last < seconds then
		return false
	end
	actions[action] = now
	return true
end

function Cooldown.remaining(player: Player, action: string, seconds: number): number
	local actions = lastUse[player]
	local last = actions and actions[action]
	if not last then
		return 0
	end
	return math.max(seconds - (os.clock() - last), 0)
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastUse[player] = nil
end)

return Cooldown
