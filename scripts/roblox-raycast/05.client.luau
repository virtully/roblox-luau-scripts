--!strict
-- How to raycast in Roblox
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-raycast
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named MouseTarget
-- LocalScript in StarterPlayerScripts named MouseTarget.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local RANGE = 500

local player = Players.LocalPlayer

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local camera = workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}

	local result = workspace:Raycast(ray.Origin, ray.Direction * RANGE, params)
	if result then
		print("Clicked", result.Instance:GetFullName(), "at", result.Position)
	end
end)
