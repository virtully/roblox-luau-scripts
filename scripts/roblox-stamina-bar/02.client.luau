--!strict
-- How to make a stamina bar in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-stamina-bar
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named ReadStamina
-- In any LocalScript: read the stamina the StaminaSprint script keeps
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function getStamina(): number
	local value = player:GetAttribute("Stamina")
	return if typeof(value) == "number" then value else 0
end

player:GetAttributeChangedSignal("Stamina"):Connect(function()
	if getStamina() < 25 then
		-- for example: grey out a dash button
	end
end)
