--!strict
-- How to make a countdown timer in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-countdown-timer
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PauseExample
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local countdown = ReplicatedStorage:WaitForChild("Countdown")

local function pause()
	local endsAt = countdown:GetAttribute("EndsAt")
	if type(endsAt) == "number" then
		countdown:SetAttribute("PausedLeft", math.max(0, endsAt - workspace:GetServerTimeNow()))
	end
end

local function resume()
	local left = countdown:GetAttribute("PausedLeft")
	if type(left) == "number" then
		countdown:SetAttribute("EndsAt", workspace:GetServerTimeNow() + left)
		countdown:SetAttribute("PausedLeft", nil)
	end
end

pause()
task.wait(5)
resume()
