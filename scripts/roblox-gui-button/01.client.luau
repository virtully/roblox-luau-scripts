--!strict
-- How to make a GUI button that opens a menu in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-gui-button
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the MenuGui ScreenGui named MenuButtons
-- LocalScript inside the MenuGui ScreenGui, named MenuButtons.
-- Each button opens its frame; opening one closes the others.
local UserInputService = game:GetService("UserInputService")

local gui = script.Parent :: ScreenGui

type Menu = { button: string, frame: string, key: Enum.KeyCode? }

-- One line per menu: the button's name, the frame's name and an optional key.
local MENUS: { Menu } = {
	{ button = "ShopButton", frame = "ShopFrame", key = Enum.KeyCode.M },
}

local frames: { Frame } = {}

local function closeAll()
	for _, frame in frames do
		frame.Visible = false
	end
end

local function toggle(frame: Frame)
	local opening = not frame.Visible
	closeAll()
	frame.Visible = opening
end

for _, menu in MENUS do
	local button = gui:WaitForChild(menu.button) :: GuiButton
	local frame = gui:WaitForChild(menu.frame) :: Frame
	table.insert(frames, frame)

	button.Activated:Connect(function()
		toggle(frame)
	end)

	local close = frame:FindFirstChild("CloseButton")
	if close and close:IsA("GuiButton") then
		close.Activated:Connect(function()
			frame.Visible = false
		end)
	end

	local key = menu.key
	if key then
		UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
			if not gameProcessedEvent and input.KeyCode == key then
				toggle(frame)
			end
		end)
	end
end
