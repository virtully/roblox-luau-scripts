--!strict
-- How to make a melee hitbox in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-hitbox-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ServerScriptService named Hitbox
-- ModuleScript in ServerScriptService named Hitbox.
-- Hitbox.run checks a box attached to a part every frame for a while and calls onHit
-- once for each character inside it. It returns a function that stops it early.
local RunService = game:GetService("RunService")

export type Options = {
	size: Vector3, -- the box size in studs
	offset: CFrame, -- where the box sits, relative to the part it follows
	duration: number, -- seconds the hitbox stays on
	exclude: { Instance }, -- things it must never hit, usually the attacker's character
	showDebug: boolean?, -- draw the box in red while testing
}

local Hitbox = {}

function Hitbox.run(follow: BasePart, options: Options, onHit: (character: Model, humanoid: Humanoid) -> ()): () -> ()
	local params = OverlapParams.new()
	params.ExcludeInstances = options.exclude
	local alreadyHit: { [Model]: boolean } = {}
	local startTime = os.clock()

	local debugBox: Part? = nil
	if options.showDebug then
		local box = Instance.new("Part")
		box.Name = "HitboxDebug"
		box.Anchored = true
		box.CanCollide = false
		box.CanTouch = false
		box.CanQuery = false
		box.Transparency = 0.7
		box.Color = Color3.fromRGB(255, 60, 60)
		box.Size = options.size
		box.Parent = workspace
		debugBox = box
	end

	local connection: RBXScriptConnection? = nil
	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if debugBox then
			debugBox:Destroy()
			debugBox = nil
		end
	end

	connection = RunService.Heartbeat:Connect(function()
		if os.clock() - startTime > options.duration or not follow:IsDescendantOf(workspace) then
			stop()
			return
		end
		local boxCFrame = follow.CFrame * options.offset
		if debugBox then
			debugBox.CFrame = boxCFrame
		end
		for _, part in workspace:GetPartBoundsInBox(boxCFrame, options.size, params) do
			local model = part:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if model and humanoid and humanoid.Health > 0 and not alreadyHit[model] then
				alreadyHit[model] = true
				task.spawn(onHit, model, humanoid)
			end
		end
	end)

	return stop
end

return Hitbox
