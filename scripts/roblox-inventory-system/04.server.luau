--!strict
-- How to make an inventory system in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-inventory-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Apple Part in Workspace named ItemPickup
-- Put this Script inside a Part and give the Part two attributes:
-- ItemId (a string, such as apple) and Amount (a number, such as 1).
local ServerScriptService = game:GetService("ServerScriptService")

type InventoryApi = {
	add: (player: Player, itemId: string, amount: number) -> number,
	spaceFor: (player: Player, itemId: string) -> number,
}
local InventoryService = require(ServerScriptService:WaitForChild("InventoryService")) :: InventoryApi

local part = script.Parent :: BasePart
local RESPAWN_SECONDS = 15

local itemId = part:GetAttribute("ItemId")
local amount = part:GetAttribute("Amount")
if typeof(itemId) ~= "string" or typeof(amount) ~= "number" or amount < 1 then
	error(`{part:GetFullName()} needs an ItemId (string) and an Amount (number, 1 or more) attribute`)
end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Pick up"
prompt.ObjectText = part.Name
prompt.Parent = part

local visibleTransparency = part.Transparency

prompt.Triggered:Connect(function(player: Player)
	if not prompt.Enabled then
		return -- someone else collected it a moment ago
	end
	-- Check the distance on the server instead of trusting the request
	local character = player.Character
	if not character then
		return
	end
	local distance = (character:GetPivot().Position - part.Position).Magnitude
	if distance > prompt.MaxActivationDistance + 5 then
		return
	end
	if InventoryService.spaceFor(player, itemId) < amount then
		return -- not enough room: leave the pickup where it is
	end
	InventoryService.add(player, itemId, amount)

	prompt.Enabled = false
	part.Transparency = 1
	task.wait(RESPAWN_SECONDS)
	part.Transparency = visibleTransparency
	prompt.Enabled = true
end)
