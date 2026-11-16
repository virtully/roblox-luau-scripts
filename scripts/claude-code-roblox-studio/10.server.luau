--!strict
-- How to connect Claude to Roblox Studio with Claude Code
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/claude-code-roblox-studio
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named ToolRequests
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local COOLDOWN_SECONDS = 1
local MAX_NAME_LENGTH = 50
local toolsFolder = ServerStorage:WaitForChild("Tools")

-- Script Sync only syncs scripts and folders, so the server makes its own remote.
local function getRemote(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local requestTool = getRemote("RequestTool")
local lastRequest: { [Player]: number } = {}

local function onRequestTool(player: Player, toolName: unknown)
	-- Ignore a request that arrives after the player has left.
	if player.Parent ~= Players then
		return
	end

	-- 1. Check the argument: a client can send anything.
	if typeof(toolName) ~= "string" or #toolName == 0 or #toolName > MAX_NAME_LENGTH then
		return
	end

	-- 2. Limit how often one player can ask.
	local now = os.clock()
	local last = lastRequest[player]
	if last ~= nil and now - last < COOLDOWN_SECONDS then
		return
	end
	lastRequest[player] = now

	-- 3. The server decides. Add your own ownership check here (a game pass, a purchase record).
	local template = toolsFolder:FindFirstChild(toolName)
	if not (template and template:IsA("Tool")) then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	if not backpack or backpack:FindFirstChild(toolName) then
		return
	end
	if character and character:FindFirstChild(toolName) then
		return
	end

	template:Clone().Parent = backpack
end

requestTool.OnServerEvent:Connect(onRequestTool)

-- 4. Per-player cleanup.
Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
end)
