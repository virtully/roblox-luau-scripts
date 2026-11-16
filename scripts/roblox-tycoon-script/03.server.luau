--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TycoonDroppers
local Debris = game:GetService("Debris")

local tycoons = workspace:WaitForChild("Tycoons")

local MAX_DROPS_PER_TYCOON = 50 -- live drops at once; a dropper skips its turn at the cap
local DROP_LIFETIME = 30 -- seconds; removes drops that fall off or get stuck
local TICK = 0.2 -- how often the loop checks the droppers

-- When each dropper may drop next. Bought droppers are hidden, never destroyed,
-- so these entries stay valid for the life of the server.
local nextDropAt: { [BasePart]: number } = {}

local function positiveNumber(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return default
end

local function ownerIdOf(tycoon: Instance): number
	local id = tycoon:GetAttribute("OwnerId")
	return if typeof(id) == "number" then id else 0
end

-- Each plot keeps its drops in its own folder. The collector pays only for drops in it.
local function dropsFolder(tycoon: Model): Folder
	local existing = tycoon:FindFirstChild("Drops")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Drops"
	folder.Parent = tycoon
	return folder
end

local function spawnDrop(tycoon: Model, dropper: BasePart)
	local drops = dropsFolder(tycoon)
	if #drops:GetChildren() >= MAX_DROPS_PER_TYCOON then
		return
	end

	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Size = Vector3.new(1, 1, 1)
	drop.Color = dropper.Color
	drop.Material = Enum.Material.SmoothPlastic
	drop.CFrame = dropper.CFrame * CFrame.new(0, -(dropper.Size.Y / 2 + 0.6), 0) -- just under the dropper
	drop:SetAttribute("Value", positiveNumber(dropper, "DropValue", 1))
	drop.Parent = drops

	-- The server simulates the drop, so no player's device can move it or fake its touches
	if drop:CanSetNetworkOwnership() then
		drop:SetNetworkOwner(nil)
	end
	Debris:AddItem(drop, DROP_LIFETIME)
end

-- Clear a plot's drops when its owner leaves
local function watchOwner(tycoon: Model)
	tycoon:GetAttributeChangedSignal("OwnerId"):Connect(function()
		if ownerIdOf(tycoon) == 0 then
			dropsFolder(tycoon):ClearAllChildren()
		end
	end)
end

for _, tycoon in tycoons:GetChildren() do
	if tycoon:IsA("Model") then
		watchOwner(tycoon)
	end
end

while true do
	local now = os.clock()
	for _, tycoon in tycoons:GetChildren() do
		local droppers = tycoon:FindFirstChild("Droppers")
		if tycoon:IsA("Model") and droppers and ownerIdOf(tycoon) ~= 0 then
			for _, dropper in droppers:GetChildren() do
				if dropper:IsA("BasePart") and now >= (nextDropAt[dropper] or 0) then
					nextDropAt[dropper] = now + positiveNumber(dropper, "Interval", 2)
					spawnDrop(tycoon, dropper)
				end
			end
		end
	end
	task.wait(TICK)
end
