--!strict
-- How to make a custom loading screen in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-loading-screen
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in ReplicatedFirst named LoadingScreen
-- LocalScript in ReplicatedFirst named LoadingScreen, with your own ScreenGui named
-- LoadingScreen inside it (design it in StarterGui, then drag it onto this script).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local MIN_SECONDS = 2

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
local gui = (script:WaitForChild("LoadingScreen") :: ScreenGui):Clone()
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

local started = os.clock()
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local shownFor = os.clock() - started
if shownFor < MIN_SECONDS then
	task.wait(MIN_SECONDS - shownFor)
end
gui:Destroy()
