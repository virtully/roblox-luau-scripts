--!strict
-- How to add chat tags in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-chat-tags
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ChatTagService
-- Script in ServerScriptService named ChatTagService.
-- Decides each player's chat tag and stores it in attributes every client can read.
local GroupService = game:GetService("GroupService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ADMIN_USER_IDS: { [number]: boolean } = {
	-- [123456789] = true,
}
local GROUP_ID = 0 -- your group's ID, or 0 for no rank tags
local STAFF_RANK = 200 -- group members at or above this rank get the Staff tag
local VIP_PASS_ID = 0 -- your VIP pass ID, or 0 for no VIP tag

type Tag = { text: string, color: Color3, nameColor: Color3? }

-- Highest first: a player gets the first tag they qualify for
local TAGS: { [string]: Tag } = {
	owner = { text = "Owner", color = Color3.fromRGB(255, 85, 85), nameColor = Color3.fromRGB(255, 170, 170) },
	admin = { text = "Admin", color = Color3.fromRGB(255, 140, 60) },
	staff = { text = "Staff", color = Color3.fromRGB(90, 170, 255) },
	vip = { text = "VIP", color = Color3.fromRGB(255, 205, 60), nameColor = Color3.fromRGB(255, 230, 150) },
}

local function hasStaffRank(player: Player): boolean
	if GROUP_ID == 0 then
		return false
	end
	-- Asks Roblox's servers, so it can fail. A failure means no tag, not an error.
	local ok, info = pcall(function()
		return GroupService:GetRolesInGroupAsync(player.UserId, GROUP_ID)
	end)
	if ok and type(info) == "table" and type(info.Roles) == "table" then
		for _, role in info.Roles do
			if type(role) == "table" and type(role.Rank) == "number" and role.Rank >= STAFF_RANK then
				return true
			end
		end
	end
	return false
end

local function ownsVip(player: Player): boolean
	if VIP_PASS_ID == 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
	end)
	return ok and owns == true
end

local function pickTag(player: Player): Tag?
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
		return TAGS.owner
	elseif ADMIN_USER_IDS[player.UserId] then
		return TAGS.admin
	elseif hasStaffRank(player) then
		return TAGS.staff
	elseif ownsVip(player) then
		return TAGS.vip
	end
	return nil
end

local function applyTag(player: Player, tag: Tag?)
	-- Attributes on the Player are copied to every client
	player:SetAttribute("ChatTag", if tag then tag.text else nil)
	player:SetAttribute("ChatTagColor", if tag then tag.color else nil)
	player:SetAttribute("NameColor", if tag then tag.nameColor else nil)
end

Players.PlayerAdded:Connect(function(player: Player)
	applyTag(player, pickTag(player))
end)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		applyTag(player, pickTag(player))
	end)
end

-- Someone bought VIP during this session: give the tag now, unless they already have a higher one
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
	if wasPurchased and passId == VIP_PASS_ID and player:GetAttribute("ChatTag") == nil then
		applyTag(player, TAGS.vip)
	end
end)
