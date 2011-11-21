--[[
	bagInfo.lua
		Generic methods for accessing bag slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Cache = LibStub('LibItemCache-1.0')


--[[ Bag Slot Type ]]--

--returns true if the given slot is the backpack
function Bagnon:IsBackpack(slot)
	return slot == BACKPACK_CONTAINER
end

--returns true if the given bagSlot is an optional inventory bag slot
function Bagnon:IsBackpackBag(bagSlot)
  return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
end

--returns true if the given slot is the bank container slot
function Bagnon:IsBank(slot)
  return slot == BANK_CONTAINER
end

--returns true if the given slot is an optional bank slot
function Bagnon:IsBankBag(slot)
  return slot > NUM_BAG_SLOTS and slot < (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS + 1)
end


--[[ Bag State ]]--

--returns link, count, icon, slot, size, cached
function Bagnon:GetBagInfo(...)
  return Cache:GetBagInfo(...)
end

function Bagnon:IsBagPurchasable(player, bag)
	return not self:IsBagCached(player, bag) and (bag - NUM_BAG_SLOTS) > GetNumBankSlots()
end

function Bagnon:IsBagLocked(player, ...)
	if not self:IsBackpack(...) and not self:IsBank(...) then
    local slot, size, cached = select(4, self:GetBagInfo(player, ...))
		return not cached and IsInventoryItemLocked(slot)
	end
end

function Bagnon:IsBagCached(...)
  return select(6, self:GetBagInfo(...))
end

function Bagnon:GetBagSize(...)
  return select(5, self:GetBagInfo(...))
end

function Bagnon:BagToInventorySlot(...)
  return select(4, self:GetBagInfo(...))
end


--[[ Bag Type ]]--

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

function Bagnon:GetBagType(...)
	return self:GetBagFamily(...) or 'normal'
end

function Bagnon:GetBagFamily(player, bag)
	if self:IsBank(bag) or self:IsBackpack(bag) then
		return
	end
	
	local link = self:GetBagInfo(player, bag)
	if link then
		return BAGNON_BAG_TYPES[GetItemFamily(link)]
	end
end