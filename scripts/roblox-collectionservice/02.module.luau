--!strict
-- How to use CollectionService tags in Roblox
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-collectionservice
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named TagBinder
-- ModuleScript in ReplicatedStorage named TagBinder.
-- bind(tag, setup) -> stop: setup(instance) runs for every instance with the tag, now and later.
-- If setup returns a function, it runs when the tag is removed or the instance is destroyed.
local CollectionService = game:GetService("CollectionService")

local TagBinder = {}

type Cleanup = () -> ()

function TagBinder.bind(tag: string, setup: (instance: Instance) -> Cleanup?): () -> ()
	local cleanups: { [Instance]: Cleanup } = {}

	local function added(instance: Instance)
		if cleanups[instance] then
			return -- already set up
		end
		local ok, result = pcall(setup, instance)
		if not ok then
			warn("[TagBinder] " .. tag .. " setup failed for " .. instance:GetFullName() .. ": " .. tostring(result))
		elseif typeof(result) == "function" then
			cleanups[instance] = result
		end
	end

	local function removed(instance: Instance)
		local cleanup = cleanups[instance]
		cleanups[instance] = nil
		if cleanup then
			cleanup()
		end
	end

	local removedConnection = CollectionService:GetInstanceRemovedSignal(tag):Connect(removed)
	for _, instance in CollectionService:GetTagged(tag) do
		task.spawn(added, instance)
	end
	local addedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(added)

	-- call the returned function to stop the binding and clean everything up
	return function()
		addedConnection:Disconnect()
		removedConnection:Disconnect()
		for instance in cleanups do
			removed(instance)
		end
	end
end

return TagBinder
