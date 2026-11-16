--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PaintServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ":: any" only matters to Luau's strict type checker; it changes nothing at runtime
local RemoteGuard = require(ServerScriptService:WaitForChild("RemoteGuard")) :: any

local paintRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PaintRequest") :: RemoteEvent
local paintable = workspace:WaitForChild("Paintable")

local PALETTE = {
	Color3.fromRGB(231, 76, 60),
	Color3.fromRGB(46, 204, 113),
	Color3.fromRGB(52, 152, 219),
	Color3.fromRGB(241, 196, 15),
}
local canPaint = RemoteGuard.limiter(4, 4) -- a burst of 4, then 4 a second

paintRequest.OnServerEvent:Connect(function(player: Player, partArg: unknown, colourArg: unknown)
	local part = RemoteGuard.instanceIn(partArg, "BasePart", paintable) :: BasePart?
	local colourIndex = RemoteGuard.integer(colourArg, 1, #PALETTE) :: number?
	if not part or not colourIndex then
		return
	end
	if not RemoteGuard.isNear(player, part.Position, 30) or not canPaint(player) then
		return
	end
	part.Color = PALETTE[colourIndex]
end)
