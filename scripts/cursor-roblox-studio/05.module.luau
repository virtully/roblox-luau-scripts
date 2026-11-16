--!strict
-- How to use Cursor (or VS Code) with Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/cursor-roblox-studio
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Cooldown
--!strict
-- Remembers when each player last used something, so server code can
-- ignore repeats that arrive too fast. Server-only: it never runs on a client.

export type Tracker = {
	ready: (player: Player) -> boolean,
	forget: (player: Player) -> (),
}

local Cooldown = {}

function Cooldown.new(seconds: number): Tracker
	assert(seconds > 0, "Cooldown.new needs a positive number of seconds")
	local lastUse: { [Player]: number } = {}

	-- true (and starts a new cooldown) if this player is allowed to act now
	local function ready(player: Player): boolean
		local now = os.clock()
		local last = lastUse[player]
		if last ~= nil and now - last < seconds then
			return false
		end
		lastUse[player] = now
		return true
	end

	-- call when the player leaves, so the table does not keep old players
	local function forget(player: Player)
		lastUse[player] = nil
	end

	return { ready = ready, forget = forget }
end

return Cooldown
