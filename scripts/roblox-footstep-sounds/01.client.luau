--!strict
-- How to make footstep sounds by material in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-footstep-sounds
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterCharacterScripts named Footsteps
-- LocalScript in StarterCharacterScripts named Footsteps.
-- Plays a step sound for this player's character, chosen by the floor material.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local STRIDE = 5.5 -- studs walked between two steps
local MIN_SPEED = 2 -- slower than this counts as standing still

-- Which sound group each material uses. Anything missing uses "Default".
local GROUPS: { [Enum.Material]: string } = {
	[Enum.Material.Grass] = "Grass",
	[Enum.Material.LeafyGrass] = "Grass",
	[Enum.Material.Ground] = "Grass",
	[Enum.Material.Mud] = "Grass",
	[Enum.Material.Concrete] = "Stone",
	[Enum.Material.Rock] = "Stone",
	[Enum.Material.Slate] = "Stone",
	[Enum.Material.Granite] = "Stone",
	[Enum.Material.Basalt] = "Stone",
	[Enum.Material.Limestone] = "Stone",
	[Enum.Material.Marble] = "Stone",
	[Enum.Material.Sandstone] = "Stone",
	[Enum.Material.Brick] = "Stone",
	[Enum.Material.Cobblestone] = "Stone",
	[Enum.Material.Pavement] = "Stone",
	[Enum.Material.Asphalt] = "Stone",
	[Enum.Material.CeramicTiles] = "Stone",
	[Enum.Material.Pebble] = "Stone",
	[Enum.Material.Wood] = "Wood",
	[Enum.Material.WoodPlanks] = "Wood",
	[Enum.Material.Metal] = "Metal",
	[Enum.Material.DiamondPlate] = "Metal",
	[Enum.Material.CorrodedMetal] = "Metal",
	[Enum.Material.Foil] = "Metal",
	[Enum.Material.Sand] = "Sand",
	[Enum.Material.Salt] = "Sand",
	[Enum.Material.Snow] = "Snow",
	[Enum.Material.Glacier] = "Snow",
	[Enum.Material.Ice] = "Snow",
	[Enum.Material.Water] = "Water",
}

local character = script.Parent :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local soundFolder = ReplicatedStorage:WaitForChild("FootstepSounds")

-- Roblox's default character sounds include a "Running" Sound in the HumanoidRootPart.
-- Keep it silent so there is only one set of footsteps.
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
for _, child in root:GetChildren() do
	muteDefault(child)
end
root.ChildAdded:Connect(muteDefault)

-- A group is a Sound, or a Folder of Sounds to pick from at random
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

local function playStep(material: Enum.Material, loudness: number)
	local template = pickSound(GROUPS[material] or "Default")
	if not template then
		return
	end
	local sound = template:Clone()
	sound.Volume = template.Volume * loudness
	-- A slightly different pitch each step, so it never sounds like a loop
	sound.PlaybackSpeed = template.PlaybackSpeed * (0.9 + math.random() * 0.2)
	sound.Parent = root -- in the root part, so the sound comes from the character
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		sound:Destroy() -- in case Ended never fires, for example when the audio fails to load
	end)
end

local travelled = 0
RunService.Heartbeat:Connect(function(deltaTime: number)
	local material = humanoid.FloorMaterial
	local velocity = root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude -- sideways speed only
	if material == Enum.Material.Air or speed < MIN_SPEED or humanoid.Health <= 0 then
		travelled = STRIDE * 0.6 -- the first step comes quickly when you start walking again
		return
	end
	travelled += speed * deltaTime
	if travelled >= STRIDE then
		travelled -= STRIDE
		playStep(material, 1)
	end
end)

-- A louder step when landing from a jump or a fall
humanoid.StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	if new == Enum.HumanoidStateType.Landed then
		playStep(humanoid.FloorMaterial, 1.5)
	end
end)
