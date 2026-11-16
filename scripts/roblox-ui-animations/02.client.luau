--!strict
-- How to animate UI in Roblox Studio with TweenService
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-ui-animations
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named AnimateMenus
-- LocalScript in StarterPlayerScripts named AnimateMenus.
-- Gives every button in your ScreenGuis the hover and press animation, and makes
-- buttons with an "Opens" attribute open and close the frame with that name.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type UIAnimate = {
	button: (GuiButton) -> (),
	open: (GuiObject) -> (),
	close: (GuiObject) -> (),
	slideIn: (GuiObject) -> (),
}
local UIAnimate = require(ReplicatedStorage:WaitForChild("UIAnimate")) :: UIAnimate

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local done: { [Instance]: boolean } = {}

local function setUp(object: Instance)
	if done[object] or not object:IsA("GuiButton") then
		return
	end
	done[object] = true
	UIAnimate.button(object)
	-- Opens = "ShopFrame": this button opens or closes the frame named ShopFrame in the same ScreenGui
	local opens = object:GetAttribute("Opens")
	local screen = object:FindFirstAncestorOfClass("ScreenGui")
	if typeof(opens) == "string" and screen then
		object.Activated:Connect(function()
			local panel = screen:FindFirstChild(opens, true)
			if panel and panel:IsA("GuiObject") then
				if panel.Visible then
					UIAnimate.close(panel)
				else
					UIAnimate.open(panel)
				end
			end
		end)
	end
end

for _, object in playerGui:GetDescendants() do
	setUp(object)
end
playerGui.DescendantAdded:Connect(setUp)
