--!strict
-- How to make a leaderboard in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-leaderboard-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named GlobalWinsBoard
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local winsBoard = DataStoreService:GetOrderedDataStore("GlobalWins_v1")

local TOP_N = 10
local REFRESH_SECONDS = 60

-- The board: an anchored Part named WinsBoard in Workspace. The script adds the
-- SurfaceGui and the rows itself, so the Part is all you have to build.
local boardPart = workspace:WaitForChild("WinsBoard") :: BasePart

local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 50
gui.Parent = boardPart

local list = Instance.new("Frame")
list.Size = UDim2.fromScale(1, 1)
list.BackgroundColor3 = Color3.fromRGB(18, 11, 31)
list.Parent = gui

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local nameCache: { [number]: string } = {}

local function nameFor(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local result = if ok then name else "Unknown player"
	nameCache[userId] = result
	return result
end

local function recordWins(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins and wins:IsA("IntValue") then
		local ok, err = pcall(function()
			winsBoard:SetAsync(tostring(player.UserId), wins.Value)
		end)
		if not ok then
			warn(`Could not record wins for {player.Name}: {err}`)
		end
	end
end

local function refresh()
	local ok, pages = pcall(function()
		return winsBoard:GetSortedAsync(false, TOP_N)
	end)
	if not ok then
		warn(`Could not read the wins board: {pages}`)
		return
	end

	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for rank, entry in pages:GetCurrentPage() do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1 / TOP_N, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Text = `{rank}. {nameFor(tonumber(entry.key) or 0)}   {entry.value}`
		label.LayoutOrder = rank
		label.Parent = list
	end
end

while true do
	for _, player in Players:GetPlayers() do
		recordWins(player)
	end
	refresh()
	task.wait(REFRESH_SECONDS)
end
