--!strict
-- How to make obby checkpoints in Roblox Studio (with saving)
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-obby-checkpoints
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in a TextButton in a ScreenGui named SkipButton
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local SKIP_STAGE_PRODUCT_ID = 0 -- the same ID as in SkipStageProduct

local player = Players.LocalPlayer
local button = script.Parent :: GuiButton
local stage = player:WaitForChild("leaderstats"):WaitForChild("Stage") :: IntValue

-- Hide the button on the last stage, where there is nothing left to skip.
-- This is for the player's benefit only: the server decides what a skip does.
local function refresh()
	local lastStage = workspace:GetAttribute("ObbyLastStage")
	button.Visible = type(lastStage) == "number" and stage.Value < lastStage
end

button.Activated:Connect(function()
	MarketplaceService:PromptProductPurchase(player, SKIP_STAGE_PRODUCT_ID)
end)

stage.Changed:Connect(refresh)
workspace:GetAttributeChangedSignal("ObbyLastStage"):Connect(refresh)
refresh()
