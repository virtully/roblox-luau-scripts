--!strict
-- How to make a tool in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tool-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in the Potion Tool named PotionScript
-- Script inside the Potion Tool, named PotionScript.
-- Heals the holder on click, with a cooldown and a limited number of uses.
local tool = script.Parent :: Tool

local HEAL_AMOUNT = 40
local COOLDOWN_SECONDS = 3

local lastUse = 0

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastUse < COOLDOWN_SECONDS then
		return
	end
	-- the tool is inside the character while it is held
	local character = tool.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return -- nobody to heal, or already at full health: do not waste a use
	end
	local uses = tool:GetAttribute("Uses")
	if typeof(uses) ~= "number" or uses <= 0 then
		return
	end
	lastUse = now
	humanoid.Health = math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
	tool:SetAttribute("Uses", uses - 1)
	tool.ToolTip = (uses - 1) .. " drinks left"
	if uses - 1 <= 0 then
		tool:Destroy()
	end
end)
