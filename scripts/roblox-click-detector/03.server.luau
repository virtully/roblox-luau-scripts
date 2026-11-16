--!strict
-- How to use a ClickDetector in Roblox
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-click-detector
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named Clickables
-- Script in ServerScriptService named Clickables.
local CollectionService = game:GetService("CollectionService")

local TAG = "Clickable"
local COOLDOWN_SECONDS = 1

local function setUp(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChildOfClass("ClickDetector") then
		return
	end
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 20
	detector.Parent = part

	local lastClick: { [Player]: number } = {}
	detector.MouseClick:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastClick[player] or 0) < COOLDOWN_SECONDS then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) or (root.Position - part.Position).Magnitude > detector.MaxActivationDistance + 5 then
			return -- too far away to have clicked honestly
		end
		lastClick[player] = now
		local message = part:GetAttribute("Message")
		print(player.Name, "clicked", part.Name, if typeof(message) == "string" then message else "")
	end)
end

for _, part in CollectionService:GetTagged(TAG) do
	setUp(part)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(setUp)
