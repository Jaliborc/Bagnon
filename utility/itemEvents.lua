--[[
	BagEvents
		A library of functions for accessing and updating bag slot information

	Based on SpecialEvents-Bags by Tekkub Stoutwrithe (tekkub@gmail.com)

	ITEM_SLOT_ADD
	args:		bag, slot, link, count, locked, coolingDown
		called when a new slot becomes available to the player

	ITEM_SLOT_REMOVE
	args:		bag, slot
		called when an item slot is removed from being in use

	ITEM_SLOT_UPDATE
	args:		bag, slot, link, count, locked, coolingDown
		called when an item slot's item or item count changes

	ITEM_SLOT_UPDATE_COOLDOWN
	args:		bag, slot, coolingDown
		called when an item's cooldown starts/ends

	BANK_OPENED
	args:		none
		called when the bank has opened and all of the bagnon events have SendMessaged

	BANK_CLOSED
	args:		none
		called when the bank is closed and all of the bagnon events have SendMessaged
		
	BAG_UPDATE_TYPE
	args:	bag, type
		called when the type of a bag changes (aka, what items you can put in it changes)
--]]


local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BagEvents = Bagnon.Ears:New()
Bagnon.BagEvents = BagEvents 


--[[ privates? ]]--

local slots = {}
local bagTypes = {}

local function ToIndex(bag, slot)
	return (bag < 0 and bag*100 - slot) or bag*100 + slot
end

local function GetBagSize(bag)
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end


--[[ Startup ]]--

function BagEvents:Load()
	self.atBank = false
	self.firstVisit = true
	
	self.frame = CreateFrame('Frame')
	
	self.RegisterEvent = function(self, event)
		self.frame:RegisterEvent(event)
	end
	
	self.OnEvent = function(f, event, ...)
		if self[event] then
			self[event](self, event, ...)
		end		
	end

	self.frame:SetScript('OnEvent', self.OnEvent)
	self:RegisterEvent('PLAYER_LOGIN')
end


--[[ Update Functions ]]--

--all info
function BagEvents:AddItem(bag, slot)
	local index = ToIndex(bag,slot)
	if not slots[index] then slots[index] = {} end

	local data = slots[index]
	local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	local onCooldown = (start > 0 and duration > 0 and enable > 0)

	data[1] = link
	data[2] = count
	data[3] = locked
	data[4] = onCooldown

	self:SendMessage('ITEM_SLOT_ADD', bag, slot, link, count, locked, onCooldown)
end

function BagEvents:RemoveItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]

	if data and next(data) then
		local prevLink = data[1]
		for i in pairs(data) do
			data[i] = nil
		end
		self:SendMessage('ITEM_SLOT_REMOVE', bag, slot, prevLink)
	end
end

function BagEvents:UpdateItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]

	if data then
		local prevLink = data[1]
		local prevCount = data[2]

		local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable > 0)

		if not(prevLink == link and prevCount == count) then
			data[1] = link
			data[2] = count
			data[3] = locked
			data[4] = onCooldown

			self:SendMessage('ITEM_SLOT_UPDATE', bag, slot, link, count, locked, onCooldown)
		end
	end
end

function BagEvents:UpdateItems(bag)
	for slot = 1, GetBagSize(bag) do
		self:UpdateItem(bag, slot)
	end
end


--cooldowns
function BagEvents:UpdateCooldown(bag, slot)
	local data = slots[ToIndex(bag,slot)]

	if data and data[1] then
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable > 0)

		if data[4] ~= onCooldown then
			data[4] = onCooldown
			self:SendMessage('ITEM_SLOT_UPDATE_COOLDOWN', bag, slot, onCooldown)
		end
	end
end

function BagEvents:UpdateCooldowns(bag)
	for slot = 1, GetBagSize(bag) do
		self:UpdateCooldown(bag, slot)
	end
end

--bag sizes
function BagEvents:UpdateBagSize(bag)
	local prevSize = slots[bag*100] or 0
	local newSize = GetBagSize(bag) or 0
	slots[bag*100] = newSize

	if prevSize > newSize then
		for slot = newSize+1, prevSize do
			self:RemoveItem(bag, slot)
		end
	elseif prevSize < newSize then
		for slot = prevSize+1, newSize do
			self:AddItem(bag, slot)
		end
	end
end

function BagEvents:UpdateBagType(bag)
	local _, newType = GetContainerNumFreeSlots(bag)
	local prevType = bagTypes[bag]

	if newType ~= prevType then
		bagTypes[bag] = newType
		self:SendMessage('BAG_UPDATE_TYPE', bag, newType)
	end
end


function BagEvents:UpdateBagSizes()
	if self:AtBank() then
		for bag = 1, NUM_BAG_SLOTS + GetNumBankSlots() do
			self:UpdateBagSize(bag)
		end
	else
		for bag = 1, NUM_BAG_SLOTS do
			self:UpdateBagSize(bag)
		end
	end
	self:UpdateBagSize(KEYRING_CONTAINER)
end

function BagEvents:UpdateBagTypes()
	if self:AtBank() then
		for bag = 1, NUM_BAG_SLOTS + GetNumBankSlots() do
			self:UpdateBagType(bag)
		end
	else
		for bag = 1, NUM_BAG_SLOTS do
			self:UpdateBagType(bag)
		end
	end
end



--[[ Events ]]--

function BagEvents:PLAYER_LOGIN(...)
	self:RegisterEvent('BAG_UPDATE')
	self:RegisterEvent('BAG_UPDATE_COOLDOWN')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
	self:RegisterEvent('BANKFRAME_OPENED')
	self:RegisterEvent('BANKFRAME_CLOSED')

	self:UpdateBagSize(KEYRING_CONTAINER)
	self:UpdateItems(KEYRING_CONTAINER)

	self:UpdateBagSize(BACKPACK_CONTAINER)
	self:UpdateItems(BACKPACK_CONTAINER)
end

function BagEvents:BAG_UPDATE(event, bag)
	self:UpdateBagTypes()
	self:UpdateBagSizes()
	self:UpdateItems(bag)
end

function BagEvents:PLAYERBANKSLOTS_CHANGED(...)
	self:UpdateBagTypes()
	self:UpdateBagSizes()
	self:UpdateItems(BANK_CONTAINER)
end

function BagEvents:BANKFRAME_OPENED(...)
	self.atBank = true

	if self.firstVisit then
		self.firstVisit = nil

		self:UpdateBagSize(BANK_CONTAINER)
		self:UpdateBagTypes()
		self:UpdateBagSizes()
	end

	self:SendMessage('BANK_OPENED')
end

function BagEvents:BANKFRAME_CLOSED(...)
	self.atBank = false
	self:SendMessage('BANK_CLOSED')
end

function BagEvents:BAG_UPDATE_COOLDOWN(...)
	self:UpdateCooldowns(BACKPACK_CONTAINER)
		
	for bag = 1, NUM_BAG_SLOTS do
		self:UpdateCooldowns(bag)
	end
end

--[[ Accessor Methods ]]--

function BagEvents:AtBank()
	return self.atBank
end


--load the thing
BagEvents:Load()