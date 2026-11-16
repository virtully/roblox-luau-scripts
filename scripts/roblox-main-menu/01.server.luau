--!strict
-- How to make a main menu in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-main-menu
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named MenuService
-- Script in ServerScriptService named MenuService.
-- Players join with no character. The server spawns one when the menu's Play button
-- asks, and respawns players after they die, since automatic spawning is turned off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Also untick CharacterAutoLoads on the Players service in the Properties window,
-- so nobody spawns in the moment before this script runs.
Players.CharacterAutoLoads = false

-- This script makes PlayRequest itself, so do not add one to ReplicatedStorage by hand
local playRequest = Instance.new("RemoteEvent")
playRequest.Name = "PlayRequest"
playRequest.Parent = ReplicatedStorage

local spawning: { [Player]: boolean } = {}

local function spawnCharacter(player: Player)
	if spawning[player] then
		return -- a second Play click while the first spawn is still loading
	end
	spawning[player] = true
	local oldCharacter = player.Character
	local ok, err = pcall(function()
		player:LoadCharacterAsync()
	end)
	spawning[player] = nil
	if not ok then
		warn(`MenuService: could not spawn {player.Name}: {err}`)
		-- A failed respawn would leave a dead player stuck, so try again after a short wait.
		-- A failed first spawn needs no retry: the menu's button says Try again.
		if oldCharacter then
			task.delay(Players.RespawnTime, function()
				local current = player.Character
				if player.Parent == Players and (current == oldCharacter or current == nil) then
					spawnCharacter(player)
				end
			end)
		end
	elseif oldCharacter and oldCharacter ~= player.Character then
		oldCharacter:Destroy() -- releases the old character's connections
	end
end

-- Only a player still in the menu (no character yet) can ask to spawn. A dead
-- player still has a character, so they cannot use this to skip the respawn wait.
playRequest.OnServerEvent:Connect(function(player: Player)
	if player.Character == nil then
		spawnCharacter(player)
	end
end)

-- With CharacterAutoLoads off, nothing respawns players after they die, so do it here
local function onCharacterAdded(player: Player, character: Model)
	local respawning = false
	local function respawnLater()
		if respawning then
			return
		end
		respawning = true
		task.wait(Players.RespawnTime)
		-- Respawn only if they are still here and nothing has spawned them since
		local current = player.Character
		if player.Parent == Players and (current == character or current == nil) then
			spawnCharacter(player)
		end
	end
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(respawnLater)
	-- Falling off the map can remove the character from Workspace, and Died only fires
	-- while the Humanoid is in Workspace, so this catches that case too
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			respawnLater()
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)

	-- With streaming on, the map streams in around a player's character, and a player in
	-- the menu has none yet. Add a replication focus at the menu camera until they spawn.
	local menuCamera = workspace:FindFirstChild("MenuCamera")
	if menuCamera and menuCamera:IsA("BasePart") then
		player:AddReplicationFocus(menuCamera)
		player.CharacterAdded:Once(function()
			player:RemoveReplicationFocus(menuCamera) -- from now on the character is the focus
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	spawning[player] = nil
end)
