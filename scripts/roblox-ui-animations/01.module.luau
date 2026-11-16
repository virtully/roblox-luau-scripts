--!strict
-- How to animate UI in Roblox Studio with TweenService
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-ui-animations
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named UIAnimate
-- ModuleScript in ReplicatedStorage named UIAnimate.
-- Small tween helpers for menus: hover and press on buttons, pop a panel in and out,
-- slide a panel from off screen. Use it from any LocalScript.
local TweenService = game:GetService("TweenService")

local UIAnimate = {}

local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SLIDE = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- A UIScale grows or shrinks a frame and everything inside it, without changing its Size
local function getScale(object: GuiObject): UIScale
	local scale = object:FindFirstChildOfClass("UIScale")
	if not scale then
		local newScale = Instance.new("UIScale")
		newScale.Parent = object
		return newScale
	end
	return scale
end

-- Grow a little on hover, shrink on press, back on release
function UIAnimate.button(button: GuiButton)
	local scale = getScale(button)
	local hovering = false
	local function to(value: number)
		TweenService:Create(scale, QUICK, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		to(1.06)
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.94)
	end)
	button.MouseButton1Up:Connect(function()
		to(if hovering then 1.06 else 1)
	end)
end

-- Open: show the panel and pop it from small to full size with a slight overshoot
function UIAnimate.open(panel: GuiObject)
	local scale = getScale(panel)
	scale.Scale = 0.6
	panel.Visible = true
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
end

-- Close: shrink, then hide
function UIAnimate.close(panel: GuiObject)
	local scale = getScale(panel)
	local tween = TweenService:Create(scale, CLOSE, { Scale = 0.6 })
	tween.Completed:Connect(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed then
			panel.Visible = false
		end
	end)
	tween:Play()
end

-- Slide in from the left edge of the screen to where the panel was placed in Studio
function UIAnimate.slideIn(panel: GuiObject)
	local target = panel:GetAttribute("HomePosition")
	local home = if typeof(target) == "UDim2" then target else panel.Position
	panel:SetAttribute("HomePosition", home)
	panel.Position = UDim2.new(-1, 0, home.Y.Scale, home.Y.Offset)
	panel.Visible = true
	TweenService:Create(panel, SLIDE, { Position = home }):Play()
end

return UIAnimate
