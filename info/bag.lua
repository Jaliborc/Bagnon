--[[
	bag.lua
		Generic methods for accessing bag slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Cache = LibStub('LibItemCache-1.1')


--[[ Slot Type ]]--

function Bagnon:IsBackpack(slot)
	return slot == BACKPACK_CONTAINER
end

function Bagnon:IsBackpackBag(bagSlot)
  return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
end

function Bagnon:IsBank(slot)
  return slot == BANK_CONTAINER
end

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

function Bagnon:IsBagLocked(player, bag)
	if not self:IsBackpack(bag) and not self:IsBank(bag) then
    local slot, size, cached = select(4, self:GetBagInfo(player, bag))
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

do
	BAGNON_TRADE_TYPE = 0
	BAGNON_BAG_TYPES = {
		[0x0008] = 'leather',
		[0x0010] = 'inscri',
		[0x0020] = 'herb',
		[0x0040] = 'enchant',
		[0x0080] = 'engineer',
		[0x0200] = 'gem',
		[0x0400] = 'mine',
	 	[0x8000] = 'tackle',
	 	[0x10000] = 'cooking'
	}

	for v in ipairs(BAGNON_BAG_TYPES) do
		BAGNON_TRADE_TYPE = BAGNON_TRADE_TYPE + v
	end
end

function Bagnon:IsTradeBag(...)
	return bit.band(self:GetBagFamily(...), BAGNON_TRADE_TYPE) > 0
end

function Bagnon:GetBagType(...)
	return BAGNON_BAG_TYPES[self:GetBagFamily(...)] or 'normal'
end

function Bagnon:GetBagFamily(player, bag)
	if self:IsBank(bag) or self:IsBackpack(bag) then
		return 0
	end
	
	local link = self:GetBagInfo(player, bag)
	if link then
		return GetItemFamily(link)
	end
end