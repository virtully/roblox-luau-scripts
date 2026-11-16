--!strict
-- How to make a roleplay game in Roblox Studio
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/how-to-make-a-roleplay-game
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named JobServer
-- Script in ServerScriptService named JobServer.
-- Jobs as Teams: a player picks a job, the server checks the limit, gives the job's tools and pays wages.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

type Job = { color: BrickColor, max: number, wage: number }
local JOBS: { [string]: Job } = {
	Citizen = { color = BrickColor.new("Medium stone grey"), max = 100, wage = 5 },
	Police = { color = BrickColor.new("Bright blue"), max = 4, wage = 15 },
	Medic = { color = BrickColor.new("Bright red"), max = 3, wage = 15 },
	Chef = { color = BrickColor.new("Bright orange"), max = 2, wage = 10 },
}
local PAY_EVERY = 60 -- seconds between wages
local jobTools = ServerStorage:WaitForChild("JobTools") -- a Folder per job with its Tools

for name, job in JOBS do
	local team = Instance.new("Team")
	team.Name = name
	team.TeamColor = job.color
	team.AutoAssignable = name == "Citizen"
	team.Parent = Teams
end

local chooseJob = Instance.new("RemoteEvent")
chooseJob.Name = "ChooseJob"
chooseJob.Parent = ReplicatedStorage

chooseJob.OnServerEvent:Connect(function(player: Player, jobName: unknown)
	local job = if typeof(jobName) == "string" then JOBS[jobName] else nil
	local team = job and Teams:FindFirstChild(jobName :: string)
	if not job or not team or not team:IsA("Team") or player.Team == team then
		return
	end
	if #team:GetPlayers() >= job.max then
		return -- this job is full
	end
	player.Team = team
	player:LoadCharacterAsync() -- respawn at a SpawnLocation with this team's TeamColor
end)

-- Every new character gets the tools of the player's current job
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local folder = player.Team and jobTools:FindFirstChild(player.Team.Name)
		local backpack = player:WaitForChild("Backpack")
		if folder then
			for _, tool in folder:GetChildren() do
				tool:Clone().Parent = backpack
			end
		end
	end)
end)

-- Wages: everyone is paid by their job, so the city keeps a money flow without grinding
while true do
	task.wait(PAY_EVERY)
	for _, player in Players:GetPlayers() do
		local job = player.Team and JOBS[player.Team.Name]
		local stats = player:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")
		if job and cash and cash:IsA("IntValue") then
			cash.Value += job.wage
		end
	end
end
