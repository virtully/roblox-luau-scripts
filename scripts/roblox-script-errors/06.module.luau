--!strict
-- How to fix Roblox script errors
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-script-errors
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named Format
local Format = {}

-- Turns a number of seconds into minutes and seconds: 95 becomes "1:35"
function Format.clock(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- The module must end by returning its table. Without this line, every
-- require of it fails with: Module code did not return exactly one value
return Format
