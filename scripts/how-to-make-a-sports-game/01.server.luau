--!strict
-- How to make a sports game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-sports-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named BallServer
-- Script in ServerScriptService named BallServer.
-- The server owns the ball, checks every kick and counts goals.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local KICK_RANGE = 6 -- studs from the player to the ball
local KICK_SPEED = 90 -- studs per second at full power
local KICK_COOLDOWN = 0.4

local ball = workspace:WaitForChild("Ball") :: BasePart -- an unanchored ball
local centre = ball.CFrame
local goals = workspace:WaitForChild("Goals") :: Folder -- sensor parts named after the team that scores there
ball:SetNetworkOwner(nil) -- the server simulates the ball, so no client can move it

local kick = Instance.new("RemoteEvent")
kick.Name = "Kick"
kick.Parent = ReplicatedStorage
local lastKick: { [Player]: number } = {}

kick.OnServerEvent:Connect(function(player: Player, power: unknown)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if typeof(power) ~= "number" or not root or not root:IsA("BasePart") then
		return
	end
	local now = os.clock()
	if now - (lastKick[player] or 0) < KICK_COOLDOWN then
		return
	end
	if (ball.Position - root.Position).Magnitude > KICK_RANGE then
		return -- too far away: the client lied or lagged
	end
	lastKick[player] = now
	local strength = math.clamp(power, 0.2, 1)
	local direction = (root.CFrame.LookVector + Vector3.new(0, 0.25, 0)).Unit
	ball.AssemblyLinearVelocity = Vector3.zero
	ball:ApplyImpulse(direction * KICK_SPEED * strength * ball.AssemblyMass)
end)

local scoring = false
for _, sensor in goals:GetChildren() do
	if not sensor:IsA("BasePart") then
		continue
	end
	sensor.Touched:Connect(function(hit)
		local team = Teams:FindFirstChild(sensor.Name)
		if hit ~= ball or scoring or not team then
			return
		end
		scoring = true
		team:SetAttribute("Score", (tonumber(team:GetAttribute("Score")) or 0) + 1)
		task.wait(2) -- a moment to celebrate
		ball.AssemblyLinearVelocity = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero
		ball.CFrame = centre
		scoring = false
	end)
end

Players.PlayerRemoving:Connect(function(player)
	lastKick[player] = nil
end)
