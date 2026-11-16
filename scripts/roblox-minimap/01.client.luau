--!strict
-- How to make a minimap in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-minimap
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named Minimap
-- LocalScript in StarterPlayerScripts named Minimap.
-- A round map in the top-right corner, north up. The map covers the part named
-- MapBounds in Workspace. You are the arrow; other players are dots; parts tagged
-- "MinimapIcon" show as squares in their own colour.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAP_PIXELS = 180 -- width and height of the map on screen
local MAP_IMAGE = "" -- optional: an image of your map seen from above, e.g. "rbxassetid://123"

local player = Players.LocalPlayer
local bounds = workspace:WaitForChild("MapBounds") :: BasePart

local gui = Instance.new("ScreenGui")
gui.Name = "MinimapGui"
gui.ResetOnSpawn = false
local map = Instance.new("ImageLabel")
map.AnchorPoint = Vector2.new(1, 0)
map.Position = UDim2.new(1, -12, 0, 60)
map.Size = UDim2.fromOffset(MAP_PIXELS, MAP_PIXELS)
map.BackgroundColor3 = Color3.fromRGB(40, 70, 50)
map.Image = MAP_IMAGE
map.ClipsDescendants = true
map.Parent = gui
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0.5, 0)
round.Parent = map
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.new(1, 1, 1)
stroke.Parent = map
gui.Parent = player:WaitForChild("PlayerGui")

local function makeDot(size: number, color: Color3, isRound: boolean): Frame
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(size, size)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	if isRound then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = dot
	end
	dot.Parent = map
	return dot
end

-- You: a small triangle drawn as text, so it can point the way you face
local me = Instance.new("TextLabel")
me.AnchorPoint = Vector2.new(0.5, 0.5)
me.Size = UDim2.fromOffset(18, 18)
me.BackgroundTransparency = 1
me.Text = "^"
me.TextColor3 = Color3.fromRGB(255, 230, 80)
me.Font = Enum.Font.GothamBlack
me.TextSize = 22
me.ZIndex = 3
me.Parent = map

-- A world position to a spot on the map, from 0 to 1 across each side
local function toMap(position: Vector3): Vector2
	local offset = bounds.CFrame:PointToObjectSpace(position)
	return Vector2.new(offset.X / bounds.Size.X + 0.5, offset.Z / bounds.Size.Z + 0.5)
end

local otherDots: { [Player]: Frame } = {}
local iconDots: { [Instance]: Frame } = {}

RunService.RenderStepped:Connect(function()
	-- You
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local spot = toMap(root.Position)
		me.Position = UDim2.fromScale(spot.X, spot.Y)
		local look = bounds.CFrame:VectorToObjectSpace(root.CFrame.LookVector)
		me.Rotation = math.deg(math.atan2(look.X, -look.Z))
	end

	-- Other players
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			local dot = otherDots[other]
			if otherRoot and otherRoot:IsA("BasePart") then
				if not dot then
					dot = makeDot(8, Color3.new(1, 1, 1), true)
					otherDots[other] = dot
				end
				local spot = toMap(otherRoot.Position)
				dot.Position = UDim2.fromScale(spot.X, spot.Y)
				dot.BackgroundColor3 = if other.Team then other.TeamColor.Color else Color3.new(1, 1, 1)
				dot.Visible = true
			elseif dot then
				dot.Visible = false
			end
		end
	end
	for other, dot in otherDots do
		if other.Parent == nil then
			dot:Destroy()
			otherDots[other] = nil
		end
	end

	-- Tagged places: shops, eggs, the finish line
	for _, icon in CollectionService:GetTagged("MinimapIcon") do
		if icon:IsA("BasePart") then
			local dot = iconDots[icon] or makeDot(10, icon.Color, false)
			iconDots[icon] = dot
			local spot = toMap(icon.Position)
			dot.Position = UDim2.fromScale(spot.X, spot.Y)
		end
	end
	for icon, dot in iconDots do
		if not icon:IsDescendantOf(workspace) or not CollectionService:HasTag(icon, "MinimapIcon") then
			dot:Destroy()
			iconDots[icon] = nil
		end
	end
end)
