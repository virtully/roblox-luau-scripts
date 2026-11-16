--!strict
-- How to use ModuleScripts in Roblox Studio
-- Kind: ModuleScript. Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-modulescripts
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- ModuleScript in ReplicatedStorage named NumberFormat
-- ModuleScript in ReplicatedStorage named NumberFormat.
-- NumberFormat.short(1500) is "1.5K"; NumberFormat.commas(1500) is "1,500".
local NumberFormat = {}

local SUFFIXES = { "K", "M", "B", "T" }

function NumberFormat.short(value: number): string
	local sign = if value < 0 then "-" else ""
	local size = math.abs(value)
	if size < 1000 then
		return sign .. tostring(math.floor(size))
	end
	local index = 0
	while size >= 1000 and index < #SUFFIXES do
		size /= 1000
		index += 1
	end
	-- One decimal place, without a trailing ".0"
	local text = string.format("%.1f", math.floor(size * 10) / 10)
	text = string.gsub(text, "%.0$", "")
	return sign .. text .. SUFFIXES[index]
end

function NumberFormat.commas(value: number): string
	local text = tostring(math.floor(math.abs(value)))
	-- Add a comma before every group of three digits, counting from the right
	local result = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
	result = string.gsub(result, "^,", "")
	return (if value < 0 then "-" else "") .. result
end

return NumberFormat
