--!strict
-- How to make a parkour game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-parkour-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named SpeedrunTimer
-- Script in ServerScriptService named SpeedrunTimer.
-- Times runs on the server: touch Start, touch every part in the Checkpoints folder
-- in order (named 1, 2, 3 ...), touch Finish. Best times go to an ordered data store.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local MIN_SECONDS = 20 -- faster than any honest run: anything below is rejected
local bestTimes = DataStoreService:GetOrderedDataStore("BestTimes_v1")
local course = workspace:WaitForChild("Course")
local checkpoints = course:WaitForChild("Checkpoints")
local runs: { [Player]: { started: number, next: number } } = {}

local function playerFrom(hit: BasePart): Player?
	local character = hit.Parent
	return if character and character:IsA("Model") then Players:GetPlayerFromCharacter(character) else nil
end

local function finish(player: Player, seconds: number)
	local ms = math.floor(seconds * 1000) -- ordered data stores hold whole numbers
	player:SetAttribute("LastRun", ms)
	local ok, err = pcall(function()
		bestTimes:UpdateAsync("player_" .. player.UserId, function(old: number?): number
			if old and old <= ms then
				return old -- not a new best: keep the old time
			end
			return ms
		end)
	end)
	if not ok then
		warn("Best time not saved:", err)
	end
end

(course:WaitForChild("Start") :: BasePart).Touched:Connect(function(hit: BasePart)
	local player = playerFrom(hit)
	if player then
		runs[player] = { started = os.clock(), next = 1 } -- touching Start again restarts the run
	end
end)

for _, cp in checkpoints:GetChildren() do
	local index = tonumber(cp.Name)
	if cp:IsA("BasePart") and index then
		cp.Touched:Connect(function(hit: BasePart)
			local player = playerFrom(hit)
			local run = player and runs[player]
			if run and run.next == index then
				run.next += 1
			end
		end)
	end
end

(course:WaitForChild("Finish") :: BasePart).Touched:Connect(function(hit: BasePart)
	local player = playerFrom(hit)
	local run = player and runs[player]
	if not player or not run then
		return
	end
	runs[player] = nil
	local seconds = os.clock() - run.started
	if run.next > #checkpoints:GetChildren() and seconds >= MIN_SECONDS then
		finish(player, seconds)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	runs[player] = nil
end)
