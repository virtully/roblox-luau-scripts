--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named RemoteGuard
local Players = game:GetService("Players")

local RemoteGuard = {}

-- A real number between min and max. Rejects NaN and infinity, which pass a
-- plain type(x) == "number" check.
function RemoteGuard.number(value: unknown, min: number, max: number): number?
	if type(value) ~= "number" or not math.isfinite(value) then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

-- A whole number between min and max, for counts, indexes and quantities
function RemoteGuard.integer(value: unknown, min: number, max: number): number?
	local n = RemoteGuard.number(value, min, max)
	if n and n % 1 == 0 then
		return n
	end
	return nil
end

-- Text with a length cap. utf8.len returns nil for invalid UTF-8, which data
-- stores reject.
function RemoteGuard.text(value: unknown, maxLength: number): string?
	if type(value) ~= "string" or #value > maxLength or utf8.len(value) == nil then
		return nil
	end
	return value
end

-- An Instance of the expected class, inside the container you allow.
-- A table built to look like an Instance fails the typeof check.
function RemoteGuard.instanceIn(value: unknown, className: string, container: Instance): Instance?
	if typeof(value) ~= "Instance" then
		return nil
	end
	if not value:IsA(className) or not value:IsDescendantOf(container) then
		return nil
	end
	return value
end

-- True when the player's character is within maxDistance studs of position
function RemoteGuard.isNear(player: Player, position: Vector3, maxDistance: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - position).Magnitude <= maxDistance
end

-- A per-player rate limit. Each player may make `burst` calls at once, and
-- earns back `perSecond` calls every second. Returns a function to call
-- before doing the work: it answers true (go ahead) or false (too fast).
function RemoteGuard.limiter(burst: number, perSecond: number): (Player) -> boolean
	local buckets: { [Player]: { tokens: number, updated: number } } = {}

	Players.PlayerRemoving:Connect(function(player: Player)
		buckets[player] = nil
	end)

	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if not bucket then
			bucket = { tokens = burst, updated = now }
			buckets[player] = bucket
		end
		bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.updated) * perSecond)
		bucket.updated = now
		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end
end

return RemoteGuard
