--!strict
-- How to make an escape room game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-an-escape-room-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named PlusOneSpeed
-- Script in ServerScriptService named PlusOneSpeed.
-- The "+1 speed" escape loop: every second alive adds 1 Speed, and touching
-- the part named Exit at the end of the course gives a Win and sends you back.
local Players = game:GetService("Players")

local BASE_WALK = 16 -- Roblox's default WalkSpeed
local MAX_WALK = 300 -- a cap keeps very fast players on the map
local exit = workspace:WaitForChild("Exit") :: BasePart
local start = workspace:WaitForChild("Start") :: BasePart

local function stat(player: Player, name: string): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(name)
	return if value and value:IsA("IntValue") then value else nil
end

Players.PlayerAdded:Connect(function(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Speed", "Wins" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
end)

exit.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	local player = if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
	local wins = player and stat(player, "Wins")
	if player and character and character:IsA("Model") and wins and not player:GetAttribute("JustWon") then
		player:SetAttribute("JustWon", true) -- one Win per touch, not one per body part
		wins.Value += 1
		character:PivotTo(start.CFrame * CFrame.new(0, 4, 0))
		task.delay(1, function()
			player:SetAttribute("JustWon", nil)
		end)
	end
end)

while true do
	task.wait(1)
	for _, player in Players:GetPlayers() do
		local speed = stat(player, "Speed")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if speed and humanoid and humanoid.Health > 0 then
			speed.Value += 1 * (tonumber(player:GetAttribute("SpeedBoost")) or 1)
			humanoid.WalkSpeed = math.min(BASE_WALK + speed.Value, MAX_WALK)
		end
	end
end
