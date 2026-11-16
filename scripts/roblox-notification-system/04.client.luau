--!strict
-- How to make a notification system in Roblox Studio
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-notification-system
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in StarterPlayerScripts named CoreNotice
-- LocalScript in StarterPlayerScripts named CoreNotice.
local StarterGui = game:GetService("StarterGui")

-- SetCore can fail for the first moments of a session, before Roblox's own scripts are ready,
-- so try a few times
local function sendCoreNotification(title: string, text: string)
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = title,
				Text = text,
				Duration = 5,
			})
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

sendCoreNotification("Welcome", "Thanks for playing!")
