--!strict
-- How to make and award a badge in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-badge-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Badges
-- ModuleScript in ServerScriptService named Badges.
-- Badges.award(player, badgeId): gives the badge once, safely. Server only.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Badges = {}

local enabledCache: { [number]: boolean } = {}
local awardedThisSession: { [Player]: { [number]: boolean } } = {}

local function isEnabled(badgeId: number): boolean
	local cached = enabledCache[badgeId]
	if cached ~= nil then
		return cached
	end
	local ok, info = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)
	if not ok then
		warn("[Badges] could not read badge", badgeId, info)
		return false
	end
	enabledCache[badgeId] = info.IsEnabled == true
	return enabledCache[badgeId]
end

function Badges.award(player: Player, badgeId: number)
	local given = awardedThisSession[player]
	if not given then
		given = {}
		awardedThisSession[player] = given
	end
	if given[badgeId] or not isEnabled(badgeId) then
		return
	end
	given[badgeId] = true -- do not try again this session, even if a call below fails

	local okHas, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)
	if okHas and hasBadge then
		return -- already earned in an earlier visit
	end

	local okAward, result = pcall(function()
		return BadgeService:AwardBadgeAsync(player.UserId, badgeId)
	end)
	if not okAward then
		warn("[Badges] could not award", badgeId, "to", player.Name, result)
		given[badgeId] = nil -- allow a later retry
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	awardedThisSession[player] = nil
end)

return Badges
