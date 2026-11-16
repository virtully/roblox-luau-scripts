--!strict
-- How to make and award a badge in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-badge-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named WelcomeBadge
-- Script in ServerScriptService named WelcomeBadge.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

type BadgesModule = { award: (Player, number) -> () }
local Badges = require(ServerScriptService:WaitForChild("Badges")) :: BadgesModule

local WELCOME_BADGE_ID = 0 -- paste your badge ID

Players.PlayerAdded:Connect(function(player: Player)
	Badges.award(player, WELCOME_BADGE_ID)
end)
