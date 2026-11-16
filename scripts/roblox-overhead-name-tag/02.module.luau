--!strict
-- How to make an overhead name tag in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-overhead-name-tag
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Titles
-- ModuleScript in ServerScriptService named Titles.
-- A title from the player's group role or a VIP pass, or nil.
local GroupService = game:GetService("GroupService")
local MarketplaceService = game:GetService("MarketplaceService")

local GROUP_ID = 0 -- your group's ID
local VIP_PASS_ID = 0 -- your VIP game pass ID

local function titleFor(player: Player): { text: string, color: Color3 }?
	if GROUP_ID ~= 0 then
		local ok, result = pcall(function()
			return GroupService:GetRolesInGroupAsync(player.UserId, GROUP_ID)
		end)
		local topRole = ok and result.IsMember and result.Roles[1]
		if topRole and topRole.Rank >= 200 then
			return { text = topRole.Name, color = Color3.fromRGB(120, 200, 255) }
		end
	end
	if VIP_PASS_ID ~= 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
		end)
		if ok and owns then
			return { text = "VIP", color = Color3.fromRGB(255, 120, 220) }
		end
	end
	return nil
end

return titleFor
