--[[
	bagSlotInfo.lua
		Generic methods for accessing bag slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BagSlotInfo = {}
Bagnon.BagSlotInfo = BagSlotInfo


--[[ Slot Info ]]--

--returns true if the given bagSlot is a purchasable bank slot
function BagSlotInfo:IsBankBag(bagSlot)
	return bagSlot > NUM_BAG_SLOTS and bagSlot < (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS + 1)
end

--returns true if the given bagSlot is the bank container slot
function BagSlotInfo:IsBank(bagSlot)
	return bagSlot == BANK_CONTAINER
end

--returns true if the given bagSlot is the backpack
function BagSlotInfo:IsBackpack(bagSlot)
	return bagSlot == BACKPACK_CONTAINER
end

--returns true if the given bagSlot is an optional inventory bag slot
function BagSlotInfo:IsBackpackBag(bagSlot)
	return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
end

--returns true if the given bagSlot for the given player is cached
function BagSlotInfo:IsCached(player, bagSlot)
	if Bagnon.PlayerInfo:IsCached(player) then
		return true
	end

	if self:IsBank(bagSlot) or self:IsBankBag(bagSlot) then
		return not Bagnon.PlayerInfo:AtBank()
	end

	return false
end

--returns true if the given bagSlot is purchasable for the given player and false otherwise
function BagSlotInfo:IsPurchasable(player, bagSlot)
	local purchasedSlots
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			purchasedSlots = BagnonDB:GetNumBankSlots(player) or 0
		else
			purchasedSlots = 0
		end
	else
		purchasedSlots = GetNumBankSlots()
	end
	return bagSlot > (purchasedSlots + NUM_BAG_SLOTS)
end

function BagSlotInfo:IsLocked(player, bagSlot)
	if self:IsBackpack(bagSlot) or self:IsBank(bagSlot) or self:IsCached(player, bagSlot) then
		return false
	end
	return IsInventoryItemLocked(self:ToInventorySlot(bagSlot))
end


--[[ Slot Item Info ]]--

--returns how many items can fit in the given bag
function BagSlotInfo:GetSize(player, bagSlot)
	local size = 0
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			size = (BagnonDB:GetBagData(bagSlot, player))
		end
	elseif self:IsBank(bagSlot) then
		size = NUM_BANKGENERIC_SLOTS
	else
		size = GetContainerNumSlots(bagSlot)
	end
	return size or 0
end

--returns the itemLink, number of items in, and item icon texture of the given bagSlot
function BagSlotInfo:GetItemInfo(player, bagSlot)
	local link, texture, count, size
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			size, link, count, texture = BagnonDB:GetBagData(bagSlot, player)
		end
	else
		local invSlot = self:ToInventorySlot(bagSlot)
		link = GetInventoryItemLink('player', invSlot)
		texture = GetInventoryItemTexture('player', invSlot)
		count = GetInventoryItemCount('player', invSlot)
	end
	return link, count, texture
end


--[[ Slot Type Info ]]--

BAGNON_BAG_TYPES = {
	[0x0008] = 'leather',
	[0x0010] = 'inscri',
	[0x0020] = 'herb',
	[0x0040] = 'enchant',
	[0x0080] = 'engineer',
	[0x0200] = 'gem',
	[0x0400] = 'mine',
  [32768] = 'tackle'
}

function BagSlotInfo:GetBagType(...)
	return self:GetBagFamily(...) or 'normal'
end

function BagSlotInfo:GetBagFamily(player, bag)
	if self:IsBank(bag) or self:IsBackpack(bag) then
		return
	end
	
	local itemLink = (self:GetItemInfo(player, bag))
	if itemLink then
		return BAGNON_BAG_TYPES[GetItemFamily(itemLink)]
	end
end


--[[ Conversion Methods ]]--

function BagSlotInfo:ToInventorySlot(bagSlot)
	if self:IsBackpackBag(bagSlot) then
		return ContainerIDToInventoryID(bagSlot)
	end
	
	if self:IsBankBag(bagSlot) then
		return BankButtonIDToInvSlotID(bagSlot, 1)
	end
	
	return nil
end