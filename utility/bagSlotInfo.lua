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

--returns true if the given bagSlot is the keyring
function BagSlotInfo:IsKeyRing(bagSlot)
	return bagSlot == KEYRING_CONTAINER
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
	if self:IsBackpack(bagSlot) or self:IsKeyRing(bagSlot) or self:IsBank(bagSlot) or self:IsCached(player, bagSlot) then
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
	elseif self:IsKeyRing(bagSlot) then
		size = GetKeyRingSize()
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

function BagSlotInfo:GetBagType(player, bagSlot)
	if self:IsKeyRing(bagSlot) then
		return 256
	end

	if self:IsBank(bagSlot) or self:IsBackpack(bagSlot) then
		return 0
	end
	
	local itemLink = (self:GetItemInfo(player, bagSlot))
	if itemLink then
		return GetItemFamily(itemLink)
	end
	
	return 0
end

-- Stolen from OneBag, since my bitflag knowledge could be better
-- BAGTYPE_QUIVER = Quiver + Ammo
local BAGTYPE_QUIVER = 0x0001 + 0x0002 

function BagSlotInfo:IsAmmoBag(player, bagSlot)
	return bit.band(self:GetBagType(player, bagSlot), BAGTYPE_QUIVER) > 0
end

-- BAGTYPE_SOUL = Soul Bags
local BAGTYPE_SOUL = 0x004

function BagSlotInfo:IsShardBag(player, bagSlot)
	return bit.band(self:GetBagType(player, bagSlot), BAGTYPE_SOUL) > 0
end

-- BAGTYPE_PROFESSION = Leather + Inscription + Herb + Enchanting + Engineering + Gem + Mining
local BAGTYPE_PROFESSION = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400 

function BagSlotInfo:IsTradeBag(player, bagSlot)
	return bit.band(self:GetBagType(player, bagSlot), BAGTYPE_PROFESSION) > 0
end


--[[ Conversion Methods ]]--

--converts the given bag slot into an applicable inventory slot
function BagSlotInfo:ToInventorySlot(bagSlot)
	if self:IsKeyRing(bagSlot) then
		return KeyRingButtonIDToInvSlotID(bagSlot)
	end
	
	if self:IsBackpackBag(bagSlot) then
		return ContainerIDToInventoryID(bagSlot)
	end
	
	if self:IsBankBag(bagSlot) then
		return BankButtonIDToInvSlotID(bagSlot, 1)
	end
	
	return nil
end