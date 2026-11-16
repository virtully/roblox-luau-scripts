--!strict
-- How to make and award a badge in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-badge-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named BadgePerks
-- Script in ServerScriptService named BadgePerks.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local SUMMIT_BADGE_ID = 0 -- paste your badge ID

Players.PlayerAdded:Connect(function(player: Player)
	local ok, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, SUMMIT_BADGE_ID)
	end)
	player:SetAttribute("BeatTheObby", ok and hasBadge == true)
end)
