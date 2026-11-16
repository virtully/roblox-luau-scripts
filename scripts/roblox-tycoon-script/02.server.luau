--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TycoonOwnership
local Players = game:GetService("Players")

local tycoons = workspace:WaitForChild("Tycoons")

local function ownerIdOf(tycoon: Instance): number
	local id = tycoon:GetAttribute("OwnerId")
	return if typeof(id) == "number" then id else 0
end

-- The living player whose character touched the part, or nil for anything else
local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function ownedTycoon(player: Player): Model?
	for _, tycoon in tycoons:GetChildren() do
		if tycoon:IsA("Model") and ownerIdOf(tycoon) == player.UserId then
			return tycoon
		end
	end
	return nil
end

-- The sign above the pad, created the first time it is needed
local function signLabel(pad: BasePart): TextLabel
	local existing = pad:FindFirstChild("OwnerLabel", true)
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(240, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 80

	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Parent = billboard
	billboard.Parent = pad
	return label
end

local function release(tycoon: Model, pad: BasePart)
	tycoon:SetAttribute("OwnerId", 0)
	pad.Transparency = 0
	signLabel(pad).Text = "Free tycoon: step here to claim"
end

local function claim(tycoon: Model, pad: BasePart, player: Player)
	tycoon:SetAttribute("OwnerId", player.UserId)
	pad.Transparency = 0.7
	signLabel(pad).Text = `{player.DisplayName}'s tycoon`
end

local function setUpPad(tycoon: Model, pad: BasePart)
	release(tycoon, pad) -- every plot starts free
	pad.Touched:Connect(function(hit: BasePart)
		if ownerIdOf(tycoon) ~= 0 then
			return -- someone owns it already
		end
		local player = playerFromHit(hit)
		if player and not ownedTycoon(player) then -- one tycoon per player
			claim(tycoon, pad, player)
		end
	end)
end

for _, tycoon in tycoons:GetChildren() do
	local pad = tycoon:FindFirstChild("ClaimPad")
	if tycoon:IsA("Model") and pad and pad:IsA("BasePart") then
		setUpPad(tycoon, pad)
	else
		warn(`{tycoon:GetFullName()} needs to be a Model with a Part named ClaimPad`)
	end
end

-- Free the plot when its owner leaves, so the next player can claim it
Players.PlayerRemoving:Connect(function(player: Player)
	local tycoon = ownedTycoon(player)
	local pad = tycoon and tycoon:FindFirstChild("ClaimPad")
	if tycoon and pad and pad:IsA("BasePart") then
		release(tycoon, pad)
	end
end)
