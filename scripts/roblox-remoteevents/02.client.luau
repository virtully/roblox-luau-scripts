--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named PaintClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local paintRequest = remotes:WaitForChild("PaintRequest") :: RemoteEvent
local paintable = workspace:WaitForChild("Paintable")

local COLOUR_COUNT = 4 -- the server holds the actual colours
local selectedColour = 1

-- Only let the ray hit parts inside the Paintable folder
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { paintable }

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return -- the key or click went to the chat or a button
	end

	if input.KeyCode == Enum.KeyCode.Q then
		selectedColour = selectedColour % COLOUR_COUNT + 1
		return
	end

	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
	local isTap = input.UserInputType == Enum.UserInputType.Touch
	if isClick or isTap then
		local camera = workspace.CurrentCamera
		local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
		if result then
			-- Ask, don't tell: the server decides whether the paint happens
			paintRequest:FireServer(result.Instance, selectedColour)
		end
	end
end)
