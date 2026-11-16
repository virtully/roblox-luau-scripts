--!strict
-- How to make a tool in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tool-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GiveTools
-- Script in ServerScriptService named GiveTools.
-- Gives a tool from ServerStorage.Tools to players who touch the GiveFlashlight part.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local toolsFolder = ServerStorage:WaitForChild("Tools")
local pad = workspace:WaitForChild("GiveFlashlight") :: BasePart

local function giveTool(player: Player, toolName: string, keepAfterDeath: boolean)
	local template = toolsFolder:FindFirstChild(toolName)
	if not (template and template:IsA("Tool")) then
		warn("[GiveTools] no Tool named " .. toolName .. " in ServerStorage.Tools")
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local alreadyHas = (backpack and backpack:FindFirstChild(toolName)) or (character and character:FindFirstChild(toolName))
	if alreadyHas or not backpack then
		return
	end
	template:Clone().Parent = backpack
	local starterGear = player:FindFirstChild("StarterGear")
	if keepAfterDeath and starterGear and not starterGear:FindFirstChild(toolName) then
		template:Clone().Parent = starterGear
	end
end

pad.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	if player then
		giveTool(player, "Flashlight", true)
	end
end)
