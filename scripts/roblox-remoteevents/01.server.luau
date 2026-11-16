--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PaintServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local paintRequest = remotes:WaitForChild("PaintRequest") :: RemoteEvent
local paintable = workspace:WaitForChild("Paintable")

-- The server owns the colours. The client only sends a number that picks one.
local PALETTE = {
	Color3.fromRGB(231, 76, 60),
	Color3.fromRGB(46, 204, 113),
	Color3.fromRGB(52, 152, 219),
	Color3.fromRGB(241, 196, 15),
}
local MAX_DISTANCE = 30 -- studs between the character and the part
local COOLDOWN_SECONDS = 0.25

local lastPaint: { [Player]: number } = {}

-- The first parameter is always the player who fired. Roblox fills it in,
-- so it can be trusted. Everything after it came from the client and cannot.
paintRequest.OnServerEvent:Connect(function(player: Player, part: unknown, colourIndex: unknown)
	-- 1. Type: a real part, not a table pretending to be one
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end

	-- 2. Range: a whole number from 1 to 4. NaN and infinity fail here too.
	if type(colourIndex) ~= "number" or not math.isfinite(colourIndex) then
		return
	end
	if colourIndex % 1 ~= 0 or colourIndex < 1 or colourIndex > #PALETTE then
		return
	end

	-- 3. Allowed target: only parts in the Paintable folder, nothing else in the game
	if not part:IsDescendantOf(paintable) then
		return
	end

	-- 4. Distance: the player's character must be near the part
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	if (root.Position - part.Position).Magnitude > MAX_DISTANCE then
		return
	end

	-- 5. Rate limit: one paint per player every quarter of a second
	local now = os.clock()
	local last = lastPaint[player]
	if last and now - last < COOLDOWN_SECONDS then
		return
	end
	lastPaint[player] = now

	part.Color = PALETTE[colourIndex]
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastPaint[player] = nil
end)
