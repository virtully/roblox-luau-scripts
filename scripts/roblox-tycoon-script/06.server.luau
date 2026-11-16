--!strict
-- How to make a tycoon in Roblox Studio: dropper, conveyor, collector and buttons
-- Kind: Script (server). Full walkthrough, where it goes and how it works:
-- https://www.rocode.app/guides/roblox-tycoon-script
-- Type-checked with luau-lsp strict against Roblox API definitions. MIT License, (c) 2026 RoCode.

-- Script in ServerScriptService named TycoonButtons
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local tycoons = workspace:WaitForChild("Tycoons")

type Button = {
	part: BasePart,
	price: number,
	requires: string?,
	item: Instance,
	itemHome: Instance?,
	bought: boolean,
}

type Tycoon = {
	model: Model,
	buttonsFolder: Instance,
	stash: Folder,
	buttons: { [string]: Button },
}

-- Unbought items and hidden buttons wait here, out of the world
local stashRoot = Instance.new("Folder")
stashRoot.Name = "TycoonStash"
stashRoot.Parent = ServerStorage

local function ownerIdOf(model: Instance): number
	local id = model:GetAttribute("OwnerId")
	return if typeof(id) == "number" then id else 0
end

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function cashOf(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		return cash
	end
	return nil
end

local function readString(instance: Instance, name: string): string?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "string" and value ~= "" then value else nil
end

local function moveTo(instance: Instance, parent: Instance?)
	if instance.Parent ~= parent then
		instance.Parent = parent
	end
end

local function addPriceLabel(part: BasePart, text: string)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.MaxDistance = 60

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Text = text
	label.Parent = billboard
	billboard.Parent = part
end

-- A button shows when the plot has an owner, it is not bought yet, and the button
-- it requires (if any) is bought. An item shows once its button is bought.
local function refresh(tycoon: Tycoon)
	local owned = ownerIdOf(tycoon.model) ~= 0
	for _, button in tycoon.buttons do
		local requiredName = button.requires
		local required = if requiredName then tycoon.buttons[requiredName] else nil
		local unlocked = requiredName == nil or (required ~= nil and required.bought)
		local show = owned and unlocked and not button.bought
		moveTo(button.part, if show then tycoon.buttonsFolder else tycoon.stash)
		moveTo(button.item, if button.bought then button.itemHome else tycoon.stash)
	end
end

-- A touch only asks to buy. Every check happens here, on the server.
local function tryBuy(tycoon: Tycoon, button: Button, player: Player)
	if ownerIdOf(tycoon.model) ~= player.UserId then
		return -- not this player's plot
	end
	if button.bought or button.part.Parent ~= tycoon.buttonsFolder then
		return -- already bought, or still hidden
	end
	local cash = cashOf(player)
	if not cash or cash.Value < button.price then
		return -- not enough Cash
	end
	cash.Value -= button.price
	button.bought = true
	refresh(tycoon)
end

local function addButton(tycoon: Tycoon, part: BasePart)
	local price = part:GetAttribute("Price")
	local itemName = readString(part, "Unlocks")
	local item = if itemName then tycoon.model:FindFirstChild(itemName, true) else nil
	if typeof(price) ~= "number" or price < 0 or item == nil then
		warn(`{part:GetFullName()} needs a Price number and an Unlocks name that exists in {tycoon.model.Name}`)
		return
	end

	local button: Button = {
		part = part,
		price = math.floor(price),
		requires = readString(part, "Requires"),
		item = item,
		itemHome = item.Parent,
		bought = false,
	}
	tycoon.buttons[part.Name] = button
	addPriceLabel(part, `{itemName}: {button.price} Cash`)

	part.Touched:Connect(function(hit: BasePart)
		local player = playerFromHit(hit)
		if player then
			tryBuy(tycoon, button, player)
		end
	end)
end

local function setUpTycoon(model: Model, buttonsFolder: Instance)
	local stash = Instance.new("Folder")
	stash.Name = model.Name
	stash.Parent = stashRoot

	local tycoon: Tycoon = { model = model, buttonsFolder = buttonsFolder, stash = stash, buttons = {} }
	for _, part in buttonsFolder:GetChildren() do
		if part:IsA("BasePart") then
			addButton(tycoon, part)
		end
	end
	for name, button in tycoon.buttons do
		local requiredName = button.requires
		if requiredName and tycoon.buttons[requiredName] == nil then
			warn(`{name} requires {requiredName}, which is not a button in {model.Name}`)
		end
	end

	-- A new owner starts from nothing; when the owner leaves, everything goes back
	model:GetAttributeChangedSignal("OwnerId"):Connect(function()
		if ownerIdOf(model) == 0 then
			for _, button in tycoon.buttons do
				button.bought = false
			end
		end
		refresh(tycoon)
	end)
	refresh(tycoon)
end

for _, model in tycoons:GetChildren() do
	local buttonsFolder = model:FindFirstChild("Buttons")
	if model:IsA("Model") and buttonsFolder then
		setUpTycoon(model, buttonsFolder)
	end
end
