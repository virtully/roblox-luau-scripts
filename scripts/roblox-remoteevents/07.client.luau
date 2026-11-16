--!strict
-- RemoteEvents in Roblox: client to server and back
-- Kind: LocalScript (client). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-remoteevents
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- LocalScript in the CodeBox TextBox named RedeemClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local redeemCode = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RedeemCode") :: RemoteFunction
local box = script.Parent :: TextBox

local GREEN = Color3.fromRGB(46, 204, 113)
local RED = Color3.fromRGB(231, 76, 60)

box.FocusLost:Connect(function(enterPressed: boolean)
	local code = box.Text
	if not enterPressed or code == "" then
		return
	end
	box.Text = ""
	box.PlaceholderText = "Checking..."

	-- InvokeServer pauses this function until the server's callback returns.
	-- pcall keeps the LocalScript running if the call fails.
	local ok, accepted, message = pcall(function()
		return redeemCode:InvokeServer(code)
	end)

	if ok and type(message) == "string" then
		box.PlaceholderText = message
		box.PlaceholderColor3 = if accepted == true then GREEN else RED
	else
		box.PlaceholderText = "Something went wrong, try again"
		box.PlaceholderColor3 = RED
	end
end)
