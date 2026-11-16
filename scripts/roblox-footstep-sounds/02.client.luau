--!strict
-- How to make footstep sounds by material in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-footstep-sounds
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named AllFootsteps
-- LocalScript in StarterPlayerScripts named AllFootsteps.
-- Plays footsteps for every character near this player's camera, using a ray to find the floor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local STRIDE = 5.5 -- studs walked between two steps
local MIN_SPEED = 2 -- slower than this counts as standing still
local HEAR_DISTANCE = 80 -- characters farther from the camera than this are skipped
local RAY_LENGTH = 5 -- studs below the root part to look for a floor

-- Paste the full GROUPS table from Step 2 here
local GROUPS: { [Enum.Material]: string } = {
	[Enum.Material.Grass] = "Grass",
	[Enum.Material.Wood] = "Wood",
	[Enum.Material.WoodPlanks] = "Wood",
	[Enum.Material.Concrete] = "Stone",
	[Enum.Material.Metal] = "Metal",
	[Enum.Material.Sand] = "Sand",
}

local soundFolder = ReplicatedStorage:WaitForChild("FootstepSounds")
local travelled: { [Model]: number } = {}

local function pickSound(group: string): Sound?
	local entry = soundFolder:FindFirstChild(group) or soundFolder:FindFirstChild("Default")
	if entry and entry:IsA("Sound") then
		return entry
	end
	if entry then
		local options = entry:GetChildren()
		if #options > 0 then
			local choice = options[math.random(1, #options)]
			if choice:IsA("Sound") then
				return choice
			end
		end
	end
	return nil
end

local function playStep(root: BasePart, material: Enum.Material)
	local template = pickSound(GROUPS[material] or "Default")
	if not template then
		return
	end
	local sound = template:Clone()
	sound.PlaybackSpeed = template.PlaybackSpeed * (0.9 + math.random() * 0.2)
	sound.Parent = root
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		sound:Destroy()
	end)
end

-- Mute the default "Running" sound on every character, not just this player's
local function muteDefault(child: Instance)
	if child:IsA("Sound") and child.Name == "Running" then
		child.Volume = 0
		child:GetPropertyChangedSignal("Volume"):Connect(function()
			if child.Volume ~= 0 then
				child.Volume = 0
			end
		end)
	end
end
local function onCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		for _, child in root:GetChildren() do
			muteDefault(child)
		end
		root.ChildAdded:Connect(muteDefault)
	end
	character.Destroying:Connect(function()
		travelled[character] = nil
	end)
end
local function onPlayer(player: Player)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
Players.PlayerAdded:Connect(onPlayer)

RunService.Heartbeat:Connect(function(deltaTime: number)
	local camera = workspace.CurrentCamera
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = humanoid and humanoid.RootPart
		if not (character and humanoid and root) or humanoid.Health <= 0 then
			continue
		end
		if (root.Position - camera.CFrame.Position).Magnitude > HEAR_DISTANCE then
			continue -- too far away to hear
		end

		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local params = RaycastParams.new()
		params.ExcludeInstances = { character }
		local floor = workspace:Raycast(root.Position, Vector3.new(0, -RAY_LENGTH, 0), params)
		if not floor or speed < MIN_SPEED then
			travelled[character] = STRIDE * 0.6
			continue
		end

		local distance = (travelled[character] or 0) + speed * deltaTime
		if distance >= STRIDE then
			distance -= STRIDE
			playStep(root, floor.Material)
		end
		travelled[character] = distance
	end
end)
