--!strict
-- How to make a countdown timer in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-countdown-timer
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named AddTimeExample
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local countdown = ReplicatedStorage:WaitForChild("Countdown")

-- Give everyone 30 more seconds, for example when a bonus objective is captured
local function addTime(seconds: number)
	local endsAt = countdown:GetAttribute("EndsAt")
	if type(endsAt) == "number" then
		countdown:SetAttribute("EndsAt", endsAt + seconds)
	end
end

addTime(30)
