--!strict
-- How to make a double jump in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-double-jump
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named JumpSettings
-- Script in ServerScriptService named JumpSettings.
-- Decides how many air jumps each player gets. The DoubleJump LocalScript reads it.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local AIR_JUMPS = 1 -- everyone: one extra jump (a double jump)
local PASS_AIR_JUMPS = 2 -- game pass owners: a triple jump
local TRIPLE_JUMP_PASS_ID = 0 -- your game pass ID, or 0 for no pass

local function ownsPass(player: Player): boolean
	if TRIPLE_JUMP_PASS_ID == 0 then
		return false
	end
	-- UserOwnsGamePassAsync asks Roblox's servers and can fail, so wrap it in pcall
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, TRIPLE_JUMP_PASS_ID)
	end)
	return ok and owns == true
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("AirJumps", AIR_JUMPS)
	if ownsPass(player) then
		player:SetAttribute("AirJumps", PASS_AIR_JUMPS)
	end
end

-- Someone who buys the pass during the game gets the triple jump at once
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
	if purchased and passId == TRIPLE_JUMP_PASS_ID and TRIPLE_JUMP_PASS_ID ~= 0 then
		player:SetAttribute("AirJumps", PASS_AIR_JUMPS)
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
