--!strict
-- How to make a VIP game pass door in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-vip-gamepass-door
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named VipDoorServer
-- Script in ServerScriptService named VipDoorServer.
-- Only VIP pass owners walk through parts tagged VipDoor. Non-owners inside VipArea parts are moved out.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local VIP_PASS_ID = 0 -- your pass ID from Creator Hub
local TEST_AS_OWNER = false -- true = everyone counts as an owner, in Studio only
local GUARD_SECONDS = 1 -- how often non-owners are checked inside VipArea parts
local CHECK_ATTEMPTS = 3

local DOOR_GROUP = "VipDoor"
local OWNER_GROUP = "VipPlayers"

-- The two groups pass through each other; everything else collides as normal
for _, groupName in { DOOR_GROUP, OWNER_GROUP } do
	if not workspace:IsCollisionGroupRegistered(groupName) then
		workspace:RegisterCollisionGroup(groupName)
	end
end
workspace:CollisionGroupSetCollidable(DOOR_GROUP, OWNER_GROUP, false)

local function setUpDoor(door: Instance)
	if door:IsA("BasePart") then
		door.CollisionGroup = DOOR_GROUP
		-- The LocalScript reads this to open the right purchase window
		door:SetAttribute("VipPassId", VIP_PASS_ID)
	end
end
for _, door in CollectionService:GetTagged("VipDoor") do
	setUpDoor(door)
end
CollectionService:GetInstanceAddedSignal("VipDoor"):Connect(setUpDoor)

local owners: { [Player]: boolean } = {}

local function putInGroup(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = OWNER_GROUP
		end
	end
end

local function grant(player: Player)
	if owners[player] then
		return
	end
	owners[player] = true
	player:SetAttribute("OwnsVip", true)
	if player.Character then
		putInGroup(player.Character)
	end
end

local function ownsPass(player: Player): boolean
	if TEST_AS_OWNER and RunService:IsStudio() then
		return true
	end
	if VIP_PASS_ID == 0 then
		return false
	end
	for attempt = 1, CHECK_ATTEMPTS do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
		end)
		if ok then
			return result == true
		end
		warn("VIP check failed for " .. player.Name .. " (try " .. attempt .. "): " .. tostring(result))
		task.wait(2 ^ attempt)
	end
	return false
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("OwnsVip", false)
	-- New characters (and accessories that load late) join the owner group
	player.CharacterAdded:Connect(function(character: Model)
		if owners[player] then
			putInGroup(character)
			character.DescendantAdded:Connect(function(part: Instance)
				if part:IsA("BasePart") then
					part.CollisionGroup = OWNER_GROUP
				end
			end)
		end
	end)
	if ownsPass(player) and player.Parent == Players then
		grant(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	owners[player] = nil
end)

-- Bought during this session: the server's event is the one to trust
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
	if wasPurchased and passId == VIP_PASS_ID then
		grant(player)
	end
end)

-- The VIP room guard: non-owners inside a VipArea part are moved to the VipExit part
local function isInside(area: BasePart, position: Vector3): boolean
	local offset = area.CFrame:PointToObjectSpace(position)
	local half = area.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

while true do
	task.wait(GUARD_SECONDS)
	local areas = CollectionService:GetTagged("VipArea")
	local exit = CollectionService:GetTagged("VipExit")[1]
	if #areas > 0 then
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not owners[player] and character and root and root:IsA("BasePart") then
				for _, area in areas do
					if area:IsA("BasePart") and isInside(area, root.Position) then
						if exit and exit:IsA("BasePart") then
							character:PivotTo(exit.CFrame + Vector3.new(0, 3, 0))
						else
							-- No exit part: respawn them instead
							task.spawn(function()
								player:LoadCharacterAsync()
							end)
						end
						break
					end
				end
			end
		end
	end
end
