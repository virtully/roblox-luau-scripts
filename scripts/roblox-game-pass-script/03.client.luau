--!strict
-- Roblox game pass script: sell perks the right way
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-game-pass-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named PassButton
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- What the PassConfig module returns, so strict type checking can check how it is used
type PassConfigModule = {
	ids: { [string]: number },
	attributeFor: (passName: string) -> string,
}

local PassConfig = require(ReplicatedStorage:WaitForChild("PassConfig")) :: PassConfigModule

local PASS_NAME = "VIP" -- the pass this button sells: one of the names in PassConfig.ids
local passId = PassConfig.ids[PASS_NAME] or 0
local ownedAttribute = PassConfig.attributeFor(PASS_NAME)

local player = Players.LocalPlayer
local priceText = "" -- filled in once Roblox returns the price for this player

local gui = Instance.new("ScreenGui")
gui.Name = "PassButtonGui"
gui.ResetOnSpawn = false -- keep the button when the character respawns

local button = Instance.new("TextButton")
button.Name = "BuyPass"
button.AnchorPoint = Vector2.new(0, 1)
button.Position = UDim2.new(0, 16, 1, -16)
button.Size = UDim2.fromOffset(200, 48)
button.BackgroundColor3 = Color3.fromRGB(255, 196, 61)
button.TextColor3 = Color3.fromRGB(40, 28, 0)
button.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
button.TextSize = 18
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local function refresh()
	if player:GetAttribute(ownedAttribute) == true then
		button.Text = `{PASS_NAME} owned`
		button.AutoButtonColor = false
	else
		button.Text = `Get {PASS_NAME}{priceText}`
		button.AutoButtonColor = true
	end
end

button.Activated:Connect(function()
	if player:GetAttribute(ownedAttribute) == true then
		return
	end
	if passId == 0 then
		warn(`Paste the {PASS_NAME} pass ID into PassConfig first`)
		return
	end
	-- Roblox shows its own purchase window and takes the payment.
	-- This script never grants anything: the server does that when the purchase finishes.
	MarketplaceService:PromptGamePassPurchase(player, passId)
end)

-- The server sets this attribute when the player owns the pass, or buys it now
player:GetAttributeChangedSignal(ownedAttribute):Connect(refresh)
refresh()
gui.Parent = player:WaitForChild("PlayerGui")

-- Show the price this player sees. GetProductInfoAsync asks Roblox's servers, so it is in a pcall.
if passId ~= 0 then
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(passId, Enum.InfoType.GamePass)
	end)
	if ok and info.IsForSale == true and type(info.PriceInRobux) == "number" then
		priceText = `: {info.PriceInRobux} Robux`
		refresh()
	elseif not ok then
		warn(`Could not load the {PASS_NAME} pass price: {info}`)
	end
end
