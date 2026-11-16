--!strict
-- How to fix Roblox script errors
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ShopDebug
local Players = game:GetService("Players")

local DEBUG = true -- set to false when you are done
local TAG = "[ShopServer]"

local function debugPrint(...: any)
	if DEBUG then
		print(TAG, ...)
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	debugPrint("joined:", player.Name, player.UserId)

	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn(TAG, "no leaderstats for", player.Name, "after 10 seconds")
		return
	end

	local coins = leaderstats:FindFirstChild("Coins")
	-- typeof and ClassName show what a value really is
	debugPrint("Coins is", typeof(coins), if coins then coins.ClassName else "missing")
end)
